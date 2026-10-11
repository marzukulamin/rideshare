<?php
declare(strict_types=1);
function restriction_proposal(string $kind,array $p,int $actor):array {
 $target=(int)($p['user_id']??0);$user=row('SELECT id,status,access_version version FROM rs_users WHERE id=? AND status<>"deleted" FOR UPDATE',[$target])??fail(422,'Select an existing account.');
 if($kind!=='appeal'&&$target===$actor)fail(403,'You cannot propose your own access decision.');
 if($kind!=='restriction'&&$user['status']!=='suspended')fail(409,'This account has no active suspension to review.');
 $p['account_version']=(int)$user['version'];$p['prior_status']=$user['status'];
 if($kind==='restriction'){
  $p['policy_basis']=required($p,'policy_basis',1000);$seconds=(int)($p['duration_seconds']??0);$days=(int)($p['appeal_window_days']??0);
  if(($seconds!==0&&($seconds<3600||$seconds>31536000))||$days<1||$days>365)fail(422,'Choose a reviewed restriction duration (zero means manual review), and an appeal window from 1 to 365 days.');
  $p['duration_seconds']=$seconds;$p['appeal_window_days']=$days;$p['scope']='New account activity; assigned trips and own Help remain accessible';
 }
 return $p;
}
function restriction_execute(array $u,array $r,array $p,string $evidence):void {
 $target=(int)$p['user_id'];$user=row('SELECT id,status,access_version version FROM rs_users WHERE id=? FOR UPDATE',[$target])??fail(404,'Account not found.');
 if((int)$user['version']!==(int)($p['account_version']??0)||$user['status']!==($p['prior_status']??null))fail(409,'Account access changed since this proposal. Submit a fresh review.');
 $restrict=$r['kind']==='restriction';$status=$restrict?'suspended':'active';
 sql('UPDATE rs_account_restrictions SET status="superseded",resolved_at=UTC_TIMESTAMP() WHERE user_id=? AND status IN ("active","review_required")',[$target]);
 sql('UPDATE rs_users SET status=?,version=version+1,access_version=access_version+1 WHERE id=?',[$status,$target]);
 // Restoring account access does not approve a driver, identity evidence or vehicle.
 sql('UPDATE rs_drivers SET desired_online=0,status=IF(?=1,"suspended",IF(status="suspended","review",status)),reason=?,version=version+1 WHERE user_id=?',[$restrict,$evidence,$target]);
 sql('UPDATE rs_sessions SET revoked_at=UTC_TIMESTAMP() WHERE user_id=?',[$target]);
 if($restrict){$expiry=$p['duration_seconds']?gmdate('Y-m-d H:i:s',time()+$p['duration_seconds']):null;$appeal=gmdate('Y-m-d H:i:s',time()+$p['appeal_window_days']*86400);
  sql('INSERT INTO rs_account_restrictions(request_id,user_id,applied_version,prior_status,policy_basis,appeal_until,expires_at) VALUES(?,?,?,?,?,?,?)',[$r['id'],$target,(int)$user['version']+1,$user['status'],$p['policy_basis'],$appeal,$expiry]);
  notify($target,'security','Account restriction reviewed','Reason: '.$r['reason'].'. Scope: '.$p['scope'].'. '.($expiry?'Expiry: '.$expiry.' UTC.':'A further independent review is required.').' Appeal review date: '.$appeal.' UTC. Sign in to open your own Help or submit an appeal.',null);
 }else notify($target,'security','Account access restored','An independent review restored account access. Driver approval and evidence must be reviewed separately before new work.',null);
}
function restriction_expiry():int {
 $count=0;
 foreach(rows('SELECT * FROM rs_account_restrictions WHERE status="active" AND expires_at IS NOT NULL AND expires_at<=UTC_TIMESTAMP() LIMIT 100') as $candidate)$count+=transaction(function()use($candidate){
  $user=row('SELECT id,status,access_version version FROM rs_users WHERE id=? FOR UPDATE',[$candidate['user_id']]);$r=row('SELECT * FROM rs_account_restrictions WHERE request_id=? FOR UPDATE',[$candidate['request_id']]);if(!$r||$r['status']!=='active'||strtotime($r['expires_at'])>time())return ["processed"=>0];
  $restore=$user&&$user['status']==='suspended'&&(int)$user['version']===(int)$r['applied_version'];
  if($restore){sql('UPDATE rs_users SET status=?,version=version+1,access_version=access_version+1 WHERE id=?',[$r['prior_status'],$r['user_id']]);sql('UPDATE rs_drivers SET status=IF(status="suspended","review",status),desired_online=0,version=version+1 WHERE user_id=?',[$r['user_id']]);notify((int)$r['user_id'],'security','Timed restriction ended','Account access was restored at the approved expiry. Driver eligibility still requires onboarding review.',null);}
  sql('UPDATE rs_account_restrictions SET status=?,resolved_at=UTC_TIMESTAMP() WHERE request_id=?',[$restore?'expired':'review_required',$r['request_id']]);audit(null,'restriction.expiry',$r['request_id'],$restore?'Approved timed expiry; driver approval not implied':'Account changed after restriction; independent safety review required');
  if(!$restore)foreach(rows('SELECT user_id FROM rs_roles WHERE role_key="safety" AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP())') as $staff)notify((int)$staff['user_id'],'safety','Restriction needs review','A timed restriction reached expiry, but a later account decision prevents automatic restoration. Review the account restriction record.',$r['request_id']);return ["processed"=>1];
 })["processed"];return $count;
}
