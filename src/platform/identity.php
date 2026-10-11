<?php
declare(strict_types=1);
function normalized_phone(string $value):string{$value=preg_replace('/[\s()-]+/','',$value);if(preg_match('/^01[3-9][0-9]{8}$/',$value))$value='+88'.$value;elseif(str_starts_with($value,'00880'))$value='+'.substr($value,2);elseif(preg_match('/^8801[3-9][0-9]{8}$/',$value))$value='+'.$value;if(!preg_match('/^\+[1-9][0-9]{9,14}$/',$value))fail(422,'Enter a phone with country code, or an 11-digit Bangladesh mobile number.');return $value;}
function identity_action(string $action,array $b,?array $u):?array {
 if($action==='login'){
  $phone=normalized_phone(required($b,'phone',24));$pass=required($b,'password',200);
  limit_attempts('login:'.($_SERVER['REMOTE_ADDR']??'unknown').':'.$phone,10);
  $found=row('SELECT * FROM rs_users WHERE phone=? AND status<>"deleted"',[$phone]);
  if(!$found||!password_verify($pass,$found['password_hash']))fail(422,'Phone number or password is incorrect.');
  $roles=roles_for((int)$found['id']);$staff=(bool)array_diff($roles,['customer','driver','driver_applicant']);
  if($staff&&(!$found['totp_secret']||!valid_totp($found['totp_secret'],text_value($b['code']??'',6))))fail(422,'Enter your current staff authentication code.');
  $token=bin2hex(random_bytes(32));$csrf=bin2hex(random_bytes(32));$minutes=$staff?60:43200;
  sql('INSERT INTO rs_sessions(user_id,token_hash,csrf,device_label,expires_at,mfa_at) VALUES(?,?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL ? MINUTE),?)',[$found['id'],hash('sha256',$token),$csrf,text_value($b['device']??'Browser',100),$minutes,$staff?gmdate('Y-m-d H:i:s'):null]);
  $secure=!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off';
  setcookie('rs_session',$token,['expires'=>time()+$minutes*60,'path'=>'/','secure'=>$secure,'httponly'=>true,'samesite'=>'Strict']);
  audit((int)$found['id'],'session.login',(string)$found['id'],'Authenticated local account');
  return ['ok'=>true,'token'=>($b['client']??'web')==='android'?$token:null,'csrf'=>$csrf];
 }
 if($action==='signup'){
  limit_attempts('signup:'.($_SERVER['REMOTE_ADDR']??'unknown'),5,60);
  $name=required($b,'name',140);$phone=normalized_phone(required($b,'phone',24));$pass=required($b,'password',200);
  if(!preg_match('/^\+?[0-9]{10,15}$/',$phone)||strlen($pass)<12)fail(422,'Use a valid phone and a password with at least 12 characters.');
  if(empty($b['accept_terms']))fail(422,'Review and accept the service terms.');
  $terms=row('SELECT id FROM rs_terms WHERE kind="service" AND effective_at<=UTC_TIMESTAMP() ORDER BY effective_at DESC,id DESC LIMIT 1');if(!$terms||(int)($b['terms_id']??0)!==(int)$terms['id'])fail(409,'Service terms changed. Review the current terms before creating your account.');
  $passwordHash=password_hash($pass,PASSWORD_DEFAULT);
  if(row('SELECT id FROM rs_users WHERE phone=?',[$phone]))return ['ok'=>true,'message'=>'Continue by signing in or requesting recovery. Contact verification is reviewed separately.'];
  try{return transaction(function()use($name,$phone,$passwordHash,$terms){sql('INSERT INTO rs_users(name,phone,password_hash,preferences) VALUES(?,?,?,?)',[$name,$phone,$passwordHash,j(['pin_enabled'=>true,'simple_mode'=>false,'theme'=>'dark','notifications'=>true])]);$id=(int)connection()->lastInsertId();sql('INSERT INTO rs_roles(user_id,role_key) VALUES(?,"customer")',[$id]);sql('INSERT INTO rs_consents(user_id,terms_id) VALUES(?,?)',[$id,$terms['id']]);return ['ok'=>true,'message'=>'Continue by signing in or requesting recovery. Contact verification is reviewed separately.'];});}catch(PDOException $e){if((int)($e->errorInfo[1]??0)===1062&&row('SELECT id FROM rs_users WHERE phone=?',[$phone]))return ['ok'=>true,'message'=>'Continue by signing in or requesting recovery. Contact verification is reviewed separately.'];throw $e;}
 }
 if($action==='recovery-intake'){
  limit_attempts('recovery:'.($_SERVER['REMOTE_ADDR']??'unknown'),5,60);
  $reference=identifier();$kind=required($b,'kind',24);if(!in_array($kind,['recovery','appeal','urgent']))fail(422,'Choose recovery, appeal or urgent help.');
  $access=bin2hex(random_bytes(32));sql('INSERT INTO rs_intakes(id,access_hash,kind,contact_encrypted,message_encrypted) VALUES(?,?,?,?,?)',[$reference,hash('sha256',$access),$kind,encrypt_value(required($b,'contact',140)),encrypt_value(required($b,'message',2000))]);
  audit(null,'restricted.intake',$reference,$kind);
  return ['ok'=>true,'reference'=>$reference,'access_key'=>$access,'message'=>'Keep this private access key to check status. Account access has not been restored.'];
 }
 if(in_array($action,['restricted-status','restricted-reset'])){
  limit_attempts('intake-access:'.($_SERVER['REMOTE_ADDR']??'unknown'),20);
  $i=row('SELECT * FROM rs_intakes WHERE id=? AND access_hash=?',[required($b,'reference',32),hash('sha256',required($b,'access_key',64))])??fail(422,'Check the reference and private access key.');
  if($action==='restricted-status')return ['reference'=>$i['id'],'status'=>$i['status'],'reply'=>$i['public_reply'],'updated_at'=>$i['updated_at'],'recovery_available'=>(bool)row('SELECT intake_id FROM rs_recovery_grants WHERE intake_id=? AND used_at IS NULL AND expires_at>UTC_TIMESTAMP()',[$i['id']])];
  return transaction(function()use($b,$i){$grant=row('SELECT * FROM rs_recovery_grants WHERE intake_id=? AND used_at IS NULL AND expires_at>UTC_TIMESTAMP() FOR UPDATE',[$i['id']])??fail(409,'A verified, independently approved recovery is required. Check your intake status.');$pass=required($b,'new_password',200);if(strlen($pass)<12)fail(422,'Use a password with at least twelve characters.');sql('UPDATE rs_users SET password_hash=?,version=version+1 WHERE id=?',[password_hash($pass,PASSWORD_DEFAULT),$grant['user_id']]);sql('UPDATE rs_sessions SET revoked_at=UTC_TIMESTAMP() WHERE user_id=?',[$grant['user_id']]);sql('UPDATE rs_recovery_grants SET used_at=UTC_TIMESTAMP() WHERE intake_id=?',[$i['id']]);sql('UPDATE rs_intakes SET status="completed",version=version+1,updated_at=UTC_TIMESTAMP() WHERE id=?',[$i['id']]);sql('UPDATE rs_drivers SET desired_online=0,identity_status="pending",reason="Recovery requires an identity recheck",version=version+1 WHERE user_id=?',[$grant['user_id']]);sql('UPDATE rs_documents SET status="pending",reason="Recovery requires a new manual identity decision",version=version+1 WHERE user_id=? AND kind="identity"',[$grant['user_id']]);audit((int)$grant['user_id'],'account.recovered',$i['id'],'Approved restricted recovery; all sessions revoked and driver identity recheck required');return ['ok'=>true,'message'=>'Password changed. Sign in again. Driver identity recheck remains required.'];});
 }
 if(!$u)return null;
 if($action==='logout'){sql('UPDATE rs_sessions SET revoked_at=UTC_TIMESTAMP() WHERE id=?',[$u['session_id']]);setcookie('rs_session','',['expires'=>1,'path'=>'/','httponly'=>true,'samesite'=>'Strict']);return ['ok'=>true];}
 if($action==='sessions')return ['sessions'=>rows('SELECT id,device_label,created_at,seen_at,expires_at,id=? current_session FROM rs_sessions WHERE user_id=? AND revoked_at IS NULL AND expires_at>UTC_TIMESTAMP() ORDER BY seen_at DESC',[$u['session_id'],$u['id']])];
 if($action==='revoke-other-sessions'){sql('UPDATE rs_sessions SET revoked_at=UTC_TIMESTAMP() WHERE user_id=? AND id<>?',[$u['id'],$u['session_id']]);notify($u['id'],'security','Other sessions revoked','You signed out all other devices.');return ['ok'=>true];}
 if($action==='revoke-session'){$changed=sql('UPDATE rs_sessions SET revoked_at=UTC_TIMESTAMP() WHERE id=? AND user_id=? AND revoked_at IS NULL',[(int)($b['id']??0),$u['id']]);if($changed->rowCount())notify($u['id'],'security','Device signed out','You revoked a signed-in device. Sign in again on that device if you intended to keep using it.');audit($u['id'],'session.revoke',(string)($b['id']??0),'Owner revoked session');return ['ok'=>true];}
 if($action==='profile'){
  $name=required($b,'name',140);$locale=text_value($b['locale']??$u['locale'],12);if(!in_array($locale,['en-BD','bn-BD']))fail(422,'Choose a supported language.');
  sql('UPDATE rs_users SET name=?,locale=?,version=version+1 WHERE id=?',[$name,$locale,$u['id']]);if($name!==$u['name'])sql('UPDATE rs_drivers SET identity_status="pending",desired_online=0,reason="Profile name changed; independent identity review required",version=version+1 WHERE user_id=?',[$u['id']]);return ['ok'=>true];
 }
 if($action==='password'){
  $old=required($b,'current_password',200);$new=required($b,'new_password',200);$user=row('SELECT password_hash FROM rs_users WHERE id=?',[$u['id']]);
  if(!password_verify($old,$user['password_hash'])||strlen($new)<12)fail(422,'Check your current password and use at least 12 characters for the new one.');
  sql('UPDATE rs_users SET password_hash=? WHERE id=?',[password_hash($new,PASSWORD_DEFAULT),$u['id']]);sql('UPDATE rs_sessions SET revoked_at=UTC_TIMESTAMP() WHERE user_id=? AND id<>?',[$u['id'],$u['session_id']]);notify($u['id'],'security','Password changed','Other sessions were revoked.');return ['ok'=>true];
 }
 if($action==='preferences'){
  $preferences=$u['preferences'];foreach(['pin_enabled','simple_mode','notifications','reduced_motion'] as $key)if(isset($b[$key]))$preferences[$key]=(bool)$b[$key];
  if(isset($b['pin_enabled'])&&row('SELECT trip_id FROM rs_active WHERE actor_type="customer" AND actor_id=?',[$u['id']]))fail(409,'Change PIN settings after the current trip.');
  foreach(['last_customer_tab'=>3,'last_driver_tab'=>1,'last_staff_tab'=>1] as $key=>$max)if(isset($b[$key])){if(!is_int($b[$key])||$b[$key]<0||$b[$key]>$max)fail(422,'Invalid navigation preference.');$preferences[$key]=$b[$key];}
  if(isset($b['theme'])){if(!in_array($b['theme'],['dark','light','system']))fail(422,'Choose a valid theme.');$preferences['theme']=$b['theme'];}
  sql('UPDATE rs_users SET preferences=?,version=version+1 WHERE id=?',[j($preferences),$u['id']]);return ['ok'=>true];
 }
 if($action==='terms')return ['terms'=>rows('SELECT t.*,c.accepted_at,c.withdrawn_at FROM rs_terms t LEFT JOIN rs_consents c ON c.terms_id=t.id AND c.user_id=? ORDER BY effective_at DESC',[$u['id']])];
 if($action==='accept-terms'){if(!row('SELECT id FROM rs_terms WHERE id=?',[(int)($b['id']??0)]))fail(404,'Terms not found.');sql('INSERT INTO rs_consents(user_id,terms_id) VALUES(?,?) ON DUPLICATE KEY UPDATE accepted_at=UTC_TIMESTAMP(),withdrawn_at=NULL',[$u['id'],(int)$b['id']]);return ['ok'=>true];}
 if($action==='notifications'){$offset=max(0,(int)($_GET['offset']??0));$category=text_value($_GET['category']??'',24);$list=rows('SELECT * FROM rs_notifications WHERE user_id=? AND (?="" OR category=?) AND (?=0 OR read_at IS NULL) ORDER BY created_at DESC,id DESC LIMIT 20 OFFSET '.$offset,[$u['id'],$category,$category,(int)($_GET['unread']??0)]);return ['notifications'=>$list,'categories'=>array_column(rows('SELECT DISTINCT category FROM rs_notifications WHERE user_id=? ORDER BY category',[$u['id']]),'category'),'next_offset'=>count($list)===20?$offset+20:null];}
 if($action==='notification-target'){$n=row('SELECT target_id FROM rs_notifications WHERE id=? AND user_id=?',[(int)($_GET['id']??0),$u['id']])??fail(404,'Notification not found.');$id=$n['target_id'];if(!$id)return ['type'=>null];$trip=row('SELECT * FROM rs_trips WHERE id=?',[$id]);if($trip){if(row('SELECT id FROM rs_offers WHERE trip_id=? AND driver_id=? AND status="pending"',[$id,$u['id']]))return ['type'=>'offer','id'=>$id];participant($u,$trip,true);return ['type'=>'trip','id'=>$id];}$case=row('SELECT * FROM rs_cases WHERE id=?',[$id]);if($case){case_access($u,$case);return ['type'=>'case','id'=>$id];}$request=row('SELECT * FROM rs_requests WHERE id=?',[$id]);if($request){request_access($u,$request);return ['type'=>'request','id'=>$id];}return ['type'=>null];}
 if($action==='read-notification'){sql('UPDATE rs_notifications SET read_at=UTC_TIMESTAMP() WHERE id=? AND user_id=?',[(int)($b['id']??0),$u['id']]);return ['ok'=>true];}
 if($action==='saved-place'){
  if(!empty($b['delete_id']))sql('DELETE FROM rs_saved_places WHERE id=? AND user_id=?',[(int)$b['delete_id'],$u['id']]);
  elseif(!empty($b['id']))sql('UPDATE rs_saved_places SET label=?,place_json=? WHERE id=? AND user_id=?',[required($b,'label',80),j(validate_place($b['place']??[])),(int)$b['id'],$u['id']]);
  else sql('INSERT INTO rs_saved_places(user_id,label,place_json) VALUES(?,?,?)',[$u['id'],required($b,'label',80),j(validate_place($b['place']??[]))]);return ['ok'=>true];
 }
 if($action==='contact'){
  if(!empty($b['delete_id']))sql('DELETE FROM rs_contacts WHERE id=? AND user_id=?',[(int)$b['delete_id'],$u['id']]);else{if(empty($b['consent']))fail(422,'Confirm this contact agreed to be stored.');$phone=required($b,'phone',24);if(!preg_match('/^\+?[0-9]{10,15}$/',$phone))fail(422,'Use a valid contact phone.');sql('INSERT INTO rs_contacts(user_id,name,phone,purpose) VALUES(?,?,?,?)',[$u['id'],required($b,'name',100),$phone,'trusted']);}return ['ok'=>true];
 }
 if($action==='travel-profile'){
  $kind=required($b,'kind',24);if(!in_array($kind,['personal','business']))fail(422,'Choose personal or business.');sql('INSERT INTO rs_profiles(user_id,name,kind,policy_json) VALUES(?,?,?,?)',[$u['id'],required($b,'name',80),$kind,j(['payment'=>'cash','payer'=>'self'])]);return ['ok'=>true];
 }
 return null;
}
