<?php
declare(strict_types=1);
function future_date(mixed $value):string {
 $date=DateTimeImmutable::createFromFormat('!Y-m-d',text_value($value,10));
 if(!$date||$date->format('Y-m-d')!==$value||$date->getTimestamp()<=time())fail(422,'Choose a valid future date as YYYY-MM-DD.');return $date->format('Y-m-d H:i:s');
}
function governance_execute(array $u,array $r,array $p,string $evidence):bool {
 if(in_array($r['kind'],['feedback_policy','operating_rules'])){
  $key=$r['kind']==='feedback_policy'?'feedback':'operations';$old=row('SELECT * FROM rs_settings WHERE setting_key=? FOR UPDATE',[$key]);version_guard($old,$p);$value=decode($old['value_json']);
  $limits=$key==='feedback'?['rating_window_seconds'=>[3600,31536000]]:['work_limit_seconds'=>[3600,86400],'rest_seconds'=>[900,86400],'work_warning_seconds'=>[60,3600],'document_warning_days'=>[1,30]];
  foreach($limits as $field=>[$min,$max]){if(!isset($p[$field])||!is_int($p[$field])||$p[$field]<$min||$p[$field]>$max)fail(422,'Choose a valid '.$field.' policy value.');$value[$field]=$p[$field];}
  if($key==='operations'&&$value['work_warning_seconds']>=$value['work_limit_seconds'])fail(422,'The advance warning must precede the work limit.');
  $value['policy_basis']=required($p,'policy_basis',1000);$value['owner_id']=$u['id'];$value['approved_request']=$r['id'];
  sql('UPDATE rs_settings SET value_json=?,version=version+1,updated_at=UTC_TIMESTAMP() WHERE setting_key=?',[j($value),$key]);return true;
 }
 if($r['kind']==='feature_flag'){
  $key=required($p,'key',40);if(!in_array($key,['driver_practice','discovery_cards','promotions']))fail(422,'Only implemented optional features support rollout.');$scope=required($p,'scope',20);if(!in_array($scope,['market','accounts']))fail(422,'Choose this market or an account cohort.');$ids=$p['account_ids']??[];if(!is_array($ids)||count($ids)>100)fail(422,'Choose at most 100 account IDs.');foreach($ids as $id)if(!is_int($id)||!row('SELECT id FROM rs_users WHERE id=?',[$id]))fail(422,'An account cohort contains an unknown account.');$old=row('SELECT * FROM rs_settings WHERE setting_key=? FOR UPDATE',['flag:'.$key]);if($old)version_guard($old,$p);$value=['enabled'=>(bool)($p['enabled']??false),'scope'=>$scope,'account_ids'=>$ids,'expires_at'=>future_date($p['expires_at']??''),'owner_id'=>$u['id'],'request_id'=>$r['id']];sql('INSERT INTO rs_settings(setting_key,value_json) VALUES(?,?) ON DUPLICATE KEY UPDATE value_json=VALUES(value_json),version=version+1,updated_at=UTC_TIMESTAMP()',['flag:'.$key,j($value)]);return true;
 }
 if($r['kind']==='retention_policy'){
  foreach(['trip_location_days','closed_case_days','deleted_document_days','session_days'] as $key)if(!isset($p[$key])||!is_int($p[$key])||$p[$key]<1||$p[$key]>3650)fail(422,'Choose each retention interval from 1 to 3650 days.');required($p,'legal_basis',500);required($p,'jurisdiction',80);$old=row('SELECT * FROM rs_settings WHERE setting_key="retention" FOR UPDATE');if($old)version_guard($old,$p);$p['approved_request']=$r['id'];$p['owner_id']=$u['id'];$p['approved_at']=gmdate('c');sql('INSERT INTO rs_settings(setting_key,value_json) VALUES("retention",?) ON DUPLICATE KEY UPDATE value_json=VALUES(value_json),version=version+1,updated_at=UTC_TIMESTAMP()',[j($p)]);return true;
 }

 if($r['kind']==='content'){
  $key=required($p,'key',80);if(!preg_match('/^(help|discovery|notice|template)\.[a-z0-9_-]+$/',$key))fail(422,'Use a help, discovery, notice or template content key.');
  $locale=required($p,'locale',12);if(!in_array($locale,['en-BD','bn-BD']))fail(422,'Choose a supported locale.');
  $old=row('SELECT * FROM rs_content WHERE content_key=? AND locale=? FOR UPDATE',[$key,$locale]);if($old&&(int)($p['version']??0)!==(int)$old['version'])fail(409,'Content changed. Review a new proposal.');
  $destination=!empty($p['destination'])?validate_place($p['destination']):null;
  $expiry=!empty($p['expires_at'])?future_date($p['expires_at']):null;
  sql('INSERT INTO rs_content(content_key,locale,title,body,destination,active,expires_at,author_id) VALUES(?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE title=VALUES(title),body=VALUES(body),destination=VALUES(destination),active=VALUES(active),expires_at=VALUES(expires_at),author_id=VALUES(author_id),version=version+1,updated_at=UTC_TIMESTAMP()',[$key,$locale,required($p,'title',160),required($p,'text',5000),$destination?j($destination):null,(bool)($p['active']??true),$expiry,$u['id']]);return true;
 }
 if($r['kind']==='incident'){
  $id=!empty($p['id'])?required($p,'id',32):$r['id'];$old=row('SELECT * FROM rs_incidents WHERE id=? FOR UPDATE',[$id]);if($old)version_guard($old,$p);
  $severity=required($p,'severity',12);$status=required($p,'status',20);if(!in_array($severity,['critical','high','medium','low'])||!in_array($status,['open','mitigating','monitoring','resolved']))fail(422,'Choose a valid severity and incident stage.');
  if($status==='resolved'&&(empty($p['mitigation'])||empty($p['follow_up'])))fail(422,'Closure needs mitigation evidence and owned follow-up actions.');
  sql('INSERT INTO rs_incidents(id,severity,status,owner_id,summary,user_impact,runbook,mitigation,follow_up) VALUES(?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE severity=VALUES(severity),status=VALUES(status),summary=VALUES(summary),user_impact=VALUES(user_impact),runbook=VALUES(runbook),mitigation=VALUES(mitigation),follow_up=VALUES(follow_up),version=version+1,updated_at=UTC_TIMESTAMP()',[$id,$severity,$status,$u['id'],required($p,'summary',240),required($p,'user_impact',2000),required($p,'runbook',3000),text_value($p['mitigation']??'',3000),text_value($p['follow_up']??'',3000)]);return true;
 }
 if($r['kind']==='release'){
  $id=!empty($p['id'])?required($p,'id',32):$r['id'];$old=row('SELECT * FROM rs_releases WHERE id=? FOR UPDATE',[$id]);if($old)version_guard($old,$p);
  $status=required($p,'status',20);if(!in_array($status,['staged','approved','rolling_out','paused','rolled_back','completed']))fail(422,'Choose a release stage.');
  $compatible=(bool)($p['migration_compatible']??false);if(in_array($status,['approved','rolling_out','completed'])&&!$compatible)fail(422,'Compatible additive migrations must be verified before rollout.');
  $gates=json_decode(required($p,'health_gates',4000),true);if(!is_array($gates)||!isset($gates['roles_passed'],$gates['journals_balanced'],$gates['rollback_checked']))fail(422,'Health gates must include roles_passed, journals_balanced and rollback_checked.');
  if(in_array($status,['approved','rolling_out','completed'])&&in_array(false,$gates,true))fail(409,'Resolve failed health gates before rollout.');
  sql('INSERT INTO rs_releases(id,build_version,status,owner_id,cohort,health_gates,migration_compatible,rollback_target,evidence) VALUES(?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE status=VALUES(status),health_gates=VALUES(health_gates),evidence=VALUES(evidence),version=version+1,updated_at=UTC_TIMESTAMP()',[$id,required($p,'build_version',40),$status,$u['id'],required($p,'cohort',80),j($gates),$compatible,required($p,'rollback_target',40),$evidence]);return true;
 }
 if($r['kind']==='legal_hold'){
  $target=(int)($p['user_id']??0);sql('SELECT id FROM rs_users WHERE id=? FOR UPDATE',[$target]);if(!row('SELECT id FROM rs_users WHERE id=?',[$target]))fail(422,'Choose an existing account.');
  if(!empty($p['release_id'])){sql('UPDATE rs_legal_holds SET released_at=UTC_TIMESTAMP() WHERE id=? AND user_id=? AND released_at IS NULL',[required($p,'release_id',32),$target]);return true;}
  sql('INSERT INTO rs_legal_holds(id,user_id,reason,legal_basis,jurisdiction,expires_at,created_by,request_id) VALUES(?,?,?,?,?,?,?,?)',[$r['id'],$target,required($p,'legal_reason',2000),required($p,'legal_basis',240),required($p,'jurisdiction',80),future_date($p['expires_at']??''),$u['id'],$r['id']]);return true;
 }
 return false;
}
function public_content(string $locale):array {
 $list=rows('SELECT content_key,locale,title,body,destination,version FROM rs_content WHERE active=1 AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP()) AND locale IN (?,"en-BD") ORDER BY locale="en-BD" DESC',[$locale]);
 $chosen=[];foreach($list as $item){$item['destination']=decode($item['destination']);$chosen[$item['content_key']]=$item;}return array_values($chosen);
}

function feature_enabled(array $u,string $key):bool{$flag=config('flag:'.$key);if(!$flag)return true;if(strtotime($flag['expires_at']??'1970-01-01')<time())return false;return !empty($flag['enabled'])&&(($flag['scope']??'')==='market'||in_array($u['id'],$flag['account_ids']??[],true));}
