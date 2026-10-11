<?php
declare(strict_types=1);
require_once __DIR__."/settlement.php";
function driver_wrap_up(int $id,?string $since):array{
 $start=$since?:gmdate('Y-m-d H:i:s');$data=row('SELECT COUNT(*) trip_count,COALESCE(SUM(status="completed"),0) completed,COALESCE(SUM(status="cancelled"),0) cancelled,COALESCE(SUM(status="no_show"),0) no_show,COALESCE(SUM(earning_minor),0) earning_minor,COALESCE(SUM(IF(status IN ("completed","interrupted") AND payment_status<>"under_review",fare_minor,0)),0) fare_minor FROM rs_trips WHERE driver_id=? AND ended_at>=?',[$id,$start]);$payable=-(int)sql('SELECT COALESCE(SUM(amount_minor),0) FROM rs_entries WHERE user_id=? AND account_key="driver_payable"',[$id])->fetchColumn();$held=(int)sql('SELECT COALESCE(SUM(amount_minor),0) FROM rs_entries WHERE user_id=? AND account_key="driver_cash_held"',[$id])->fetchColumn();
 $cash=(int)sql('SELECT COALESCE(SUM(e.amount_minor),0) FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE e.user_id=? AND e.account_key="driver_cash_held" AND j.kind="cash_collection" AND j.created_at>=?',[$id,$start])->fetchColumn();$tips=-(int)sql('SELECT COALESCE(SUM(e.amount_minor),0) FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE e.user_id=? AND e.account_key="driver_tip_received" AND j.created_at>=?',[$id,$start])->fetchColumn();$pending=(int)sql('SELECT COALESCE(SUM(CAST(JSON_UNQUOTE(JSON_EXTRACT(payload,"$.amount_minor")) AS SIGNED)),0) FROM rs_requests WHERE user_id=? AND kind="payout" AND status IN ("pending","approved","held","execution_failed") AND expires_at>UTC_TIMESTAMP()',[$id])->fetchColumn();
 return $data+['offers'=>(int)sql('SELECT COUNT(*) FROM rs_offers WHERE driver_id=? AND created_at>=?',[$id,$start])->fetchColumn(),'online_seconds'=>$since?max(0,time()-strtotime($since)):0,'cash_received_minor'=>$cash,'tips_received_minor'=>$tips,'payout_pending_minor'=>$pending,'net_payable_minor'=>max(0,$payable-max(0,$held)),'since'=>$since,'ended_at'=>gmdate('Y-m-d H:i:s'),'timezone'=>'Asia/Dhaka','as_of'=>gmdate('c')];
}
function driver_action(string $action,array $b,array $u):?array {
 if($action==='driver-apply'){
  marketplace_user($u);$product=(int)($b['product_id']??0);$p=row('SELECT * FROM rs_products WHERE id=? AND active=1',[$product]);if(!$p)fail(422,'Choose an enabled vehicle type.');
  $label=required($b,'vehicle',140);$plate=required($b,'plate',40);$capacity=(int)($b['capacity']??0);if($capacity<1||$capacity>(int)$p['capacity'])fail(422,'Capacity must match the product limits.');
  if(!permitted($u,'driver'))sql('INSERT IGNORE INTO rs_roles(user_id,role_key) VALUES(?,"driver_applicant")',[$u['id']]);sql('INSERT IGNORE INTO rs_drivers(user_id) VALUES(?)',[$u['id']]);
  sql('INSERT INTO rs_vehicles(driver_id,product_id,label,plate,capacity,equipment,make,model,color) VALUES(?,?,?,?,?,?,?,?,?)',[$u['id'],$product,$label,$plate,$capacity,j($b['equipment']??[]),text_value($b['make']??'',80),text_value($b['model']??'',80),text_value($b['color']??'',80)]);$id=(int)connection()->lastInsertId();sql('UPDATE rs_drivers SET active_vehicle_id=COALESCE(active_vehicle_id,?),version=version+1 WHERE user_id=?',[$id,$u['id']]);notify($u['id'],'onboarding','Application saved','Upload the required documents. Approval is pending evidence review.');return ['ok'=>true,'vehicle_id'=>$id];
 }
 if($action==='driver-overview'){
  if(!permitted($u,'driver_application'))permit_current_driver($u);$r=driver_readiness($u['id']);$r['vehicles']=rows('SELECT * FROM rs_vehicles WHERE driver_id=? ORDER BY id',[$u['id']]);$r['documents']=rows('SELECT id,vehicle_id,kind,mime,status,scan_status,expires_at,reason,version FROM rs_documents WHERE user_id=? ORDER BY id DESC',[$u['id']]);
  $r['offer_notifications']=($u['preferences']['notifications']??true)===true;$r['receiving_offers']=$r['ready']&&!empty($r['profile']['desired_online'])&&fresh_driver_location($r['profile'])&&!config('operations')['matching_paused'];$r['location_fresh']=fresh_driver_location($r['profile']??[]);
  $r['offers']=$r['receiving_offers']?rows('SELECT o.*,t.snapshot,t.fare_minor FROM rs_offers o JOIN rs_trips t ON t.id=o.trip_id WHERE o.driver_id=? AND o.status="pending" AND o.expires_at>UTC_TIMESTAMP() AND t.status="matching" ORDER BY o.created_at',[$u['id']]):[];
  $days=in_array((int)($_GET['period']??0),[7,30],true)?(int)$_GET['period']:0;$since=$days?gmdate('Y-m-d H:i:s',time()-$days*86400):'1970-01-01 00:00:00';
  $r['stats']=row('SELECT COUNT(*) total,COALESCE(SUM(status="completed"),0) completed,COALESCE(SUM(status="cancelled"),0) cancelled,COALESCE(SUM(status="no_show"),0) no_show,COALESCE(SUM(earning_minor),0) earning_minor FROM rs_trips WHERE driver_id=? AND created_at>=?',[$u['id'],$since]);$r['stats']['period_days']=$days;$r['stats']['offers']=(int)sql('SELECT COUNT(*) FROM rs_offers WHERE driver_id=? AND created_at>=?',[$u['id'],$since])->fetchColumn();
  $payable=-(int)sql('SELECT COALESCE(SUM(amount_minor),0) FROM rs_entries WHERE user_id=? AND account_key="driver_payable"',[$u['id']])->fetchColumn();$held=(int)sql('SELECT COALESCE(SUM(amount_minor),0) FROM rs_entries WHERE user_id=? AND account_key="driver_cash_held"',[$u['id']])->fetchColumn();$r['net_payable_minor']=max(0,$payable-max(0,$held));$r['cash_held_minor']=$held;$r['settlement']=settlement_state($u['id']);
  $r['ledger']=rows('SELECT e.account_key,e.amount_minor,j.kind,j.trip_id,j.evidence,j.created_at FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE e.user_id=? ORDER BY e.id DESC LIMIT 100',[$u['id']]);
  $r['active_trip_id']=row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$u['id']])['trip_id']??null;return $r;
 }
 if($action==='driver-availability'){
  permit($u,'driver');$online=(bool)($b['online']??false);$ready=driver_readiness($u['id']);if(!$ready['profile'])fail(409,'Complete enrollment first.');if($online&&!$ready['ready'])fail(409,implode(' ',$ready['reasons']));
  $d=$ready['profile'];if((bool)$d['desired_online']===$online)return ['ok'=>true,'unchanged'=>true,'wrap_up'=>decode(row('SELECT summary FROM rs_driver_shifts WHERE driver_id=? AND ended_at IS NOT NULL ORDER BY id DESC LIMIT 1',[$u['id']])['summary']??'{}')];$summary=$online?null:driver_wrap_up($u['id'],$d['online_since']);if($online)sql('INSERT INTO rs_driver_shifts(driver_id,started_at) VALUES(?,UTC_TIMESTAMP())',[$u['id']]);else sql('UPDATE rs_driver_shifts SET ended_at=UTC_TIMESTAMP(),summary=? WHERE driver_id=? AND ended_at IS NULL',[j($summary),$u['id']]);$work=(int)$ready['work_seconds'];$rest=$d['rest_until'];
  if(!$online&&$work>=(int)config('operations')['work_limit_seconds'])$rest=gmdate('Y-m-d H:i:s',time()+(int)config('operations')['rest_seconds']);
  if($rest&&strtotime($rest)<time()){$work=0;$rest=null;}
  sql('UPDATE rs_drivers SET desired_online=?,online_since=?,work_seconds=?,rest_until=?,heartbeat_at=UTC_TIMESTAMP(),version=version+1 WHERE user_id=?',[$online,$online?gmdate('Y-m-d H:i:s'):null,$work,$rest,$u['id']]);audit($u['id'],'driver.availability',(string)$u['id'],$online?'Driver went online':'Driver ended availability',null,['online'=>$online,'work_seconds'=>$work]);return ['ok'=>true,'wrap_up'=>$summary,'active_trip_preserved'=>(bool)row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$u['id']])];
 }
 if($action==='driver-heartbeat'){
  permit_current_driver($u);$d=row('SELECT * FROM rs_drivers WHERE user_id=?',[$u['id']]);if(!$d)fail(409,'Complete enrollment first.');
  $location=null;if(isset($b['lat'],$b['lng'])){$lat=(float)$b['lat'];$lng=(float)$b['lng'];$accuracy=(float)($b['accuracy']??-1);if(!is_finite($lat)||!is_finite($lng)||$lat<-90||$lat>90||$lng<-180||$lng>180||$accuracy<0||$accuracy>1000)fail(422,'Location observation is invalid.');if(!$d['desired_online']&&!row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$u['id']]))fail(409,'Offline location tracking is not enabled.');$location=j(['lat'=>$lat,'lng'=>$lng,'accuracy'=>$accuracy,'observed_at'=>gmdate('c'),'source'=>'device']);}
  if($location&&isset($b['observed_at'])){$observed=(int)$b['observed_at'];if($observed>time()+10||$observed<time()-120)fail(422,'Location observation is stale.');$loc=decode($location);$loc['observed_at']=gmdate('c',$observed);$location=j($loc);}
  sql('UPDATE rs_drivers SET heartbeat_at=UTC_TIMESTAMP(),location_json=COALESCE(?,location_json) WHERE user_id=?',[$location,$u['id']]);return ['ok'=>true];
 }
 if($action==='switch-vehicle'){
  permit($u,'driver');$d=row('SELECT * FROM rs_drivers WHERE user_id=? FOR UPDATE',[$u['id']]);if(!$d||$d['desired_online']||row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$u['id']]))fail(409,'Go offline and finish the current trip before switching vehicles.');
  $vehicle=row('SELECT * FROM rs_vehicles WHERE id=? AND driver_id=? AND status="approved"',[(int)($b['id']??0),$u['id']]);if(!$vehicle)fail(422,'Choose your approved vehicle.');sql('UPDATE rs_drivers SET active_vehicle_id=?,version=version+1 WHERE user_id=?',[$vehicle['id'],$u['id']]);audit($u['id'],'vehicle.switch',(string)$vehicle['id'],'Owner changed vehicle while offline');return ['ok'=>true];
 }
 if($action==='document-upload'){
  if(!permitted($u,'driver_application'))permit($u,'driver');$kind=required($b,'kind',32);if(!in_array($kind,['license','registration','insurance','identity','profile_photo']))fail(422,'Choose a required document type.');
  $vehicle=(int)($b['vehicle_id']??0);if($vehicle&&!row('SELECT id FROM rs_vehicles WHERE id=? AND driver_id=?',[$vehicle,$u['id']]))fail(403,'This vehicle does not belong to you.');
  $expiry=null;if(!empty($b['expires_at'])){$date=DateTimeImmutable::createFromFormat('!Y-m-d',required($b,'expires_at',10));if(!$date||$date->format('Y-m-d')!==$b['expires_at']||$date->getTimestamp()<=time())fail(422,'Enter a valid future expiry date as YYYY-MM-DD.');$expiry=$date->format('Y-m-d H:i:s');}
  if(in_array($kind,['license','registration','insurance'])&&(!$expiry||!$vehicle))fail(422,'Vehicle documents need a vehicle and a future expiry date.');
  $file=private_upload($b);
  sql('INSERT INTO rs_documents(user_id,vehicle_id,kind,storage_key,mime,checksum,expires_at,scan_status) VALUES(?,?,?,?,?,?,?,?)',[$u['id'],$vehicle?:null,$kind,$file['key'],$file['mime'],$file['checksum'],$expiry,$file['scan_status']]);
  $documentId=(int)connection()->lastInsertId();
  notify($u['id'],'onboarding','Document submitted','Your '.$kind.' document is awaiting manual review.');return ['ok'=>true,'document_id'=>$documentId];
 }
 return null;
}
