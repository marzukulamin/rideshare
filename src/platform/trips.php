<?php
declare(strict_types=1);
require_once __DIR__.'/post_trip.php';
const TERMINAL_TRIPS=['completed','cancelled','no_driver','interrupted','no_show'];
function place_view(array $p):array{$p['lat']=(float)$p['lat'];$p['lng']=(float)$p['lng'];return $p;}
function validate_place(array $place):array {
 $name=required($place,'name',160);$address=text_value($place['address']??$name,240);
 if(!isset($place['lat'],$place['lng'])||!is_numeric($place['lat'])||!is_numeric($place['lng']))fail(422,'Select a pickup and destination with coordinates.');
 $lat=(float)$place['lat'];$lng=(float)$place['lng'];if(!is_finite($lat)||!is_finite($lng)||$lat<20.5||$lat>26.8||$lng<88||$lng>93)fail(422,'Choose a place in the supported service area.');
 $market=config('market');if($lng<90.2||$lng>90.6||$lat<23.6||$lat>24.0)fail(422,'Choose a point within the installed Dhaka routing coverage.');if(distance_m($lat,$lng,(float)$market['center_lat'],(float)$market['center_lng'])>(float)$market['radius_km']*1000)fail(422,'This point is outside the configured Dhaka service area.');
 return ['name'=>$name,'address'=>$address,'lat'=>$lat,'lng'=>$lng];
}
function distance_m(float $a,float $b,float $c,float $d):int { $x=sin(deg2rad($c-$a)/2)**2+cos(deg2rad($a))*cos(deg2rad($c))*sin(deg2rad($d-$b)/2)**2;return (int)round(12742000*asin(min(1,sqrt($x)))); }
function trip_row(string $id,bool $lock=false):array { return row('SELECT * FROM rs_trips WHERE id=?'.($lock?' FOR UPDATE':''),[$id])??fail(404,'Trip not found.'); }
function participant(array $u,array $trip,bool $staff=false):void {
 if($u['id']===(int)$trip['customer_id']||$u['id']===(int)$trip['driver_id'])return;
 if(!$staff||!permitted($u,'trips'))fail(403,'You cannot access this trip.');
 if(permitted($u,'dispatch'))return;
 $cases=rows('SELECT * FROM rs_cases WHERE trip_id=?',[$trip['id']]);foreach($cases as $case){try{case_access($u,$case);return;}catch(HttpFailure $e){}}
 fail(403,'A permitted case context is required to access this trip.');
}
function trip_view(array $trip,array $u,bool $staffReveal=false):array {
 participant($u,$trip,true);$snapshot=decode($trip['snapshot']);$result=$trip;$result['snapshot']=$snapshot;$result['as_of']=gmdate('c');$result['waiting_seconds']=$trip['arrived_at']&&$trip['status']==='arrived'?max(0,time()-strtotime($trip['arrived_at'])):0;
 unset($result['pin_hash'],$result['pin_encrypted']);
 $change=row('SELECT id,after_json,fare_minor,expires_at FROM rs_trip_changes WHERE trip_id=? AND status="pending" AND trip_version=? AND expires_at>UTC_TIMESTAMP() ORDER BY created_at DESC LIMIT 1',[$trip['id'],$trip['version']]);if($change){$change['snapshot']=decode($change['after_json']);unset($change['after_json']);}$result['pending_change']=$change;$result['completed_stops']=(int)(row('SELECT completed_stops FROM rs_trip_progress WHERE trip_id=?',[$trip['id']])['completed_stops']??0);
 if($u['id']===(int)$trip['customer_id']&&!in_array($trip['status'],TERMINAL_TRIPS,true)&&$trip['pin_required'])$result['pin']=decrypt_value($trip['pin_encrypted']);
 $result['events']=rows('SELECT id,event_key,details,created_at FROM rs_events WHERE trip_id=? ORDER BY id',[$trip['id']]);
 $result['rating']=row('SELECT rating,feedback,tags,version FROM rs_ratings WHERE trip_id=? AND actor_id=?',[$trip['id'],$u['id']]);
 if($result['rating'])$result['rating']['tags']=decode($result['rating']['tags'])??[];$feedback=feedback_policy();$result['feedback_tags']=$feedback['tags'];$result['feedback_edit_until']=$trip['ended_at']?gmdate('c',strtotime($trip['ended_at'])+(int)$feedback['rating_window_seconds']):null;
 $result['messages']=rows('SELECT m.id,m.body,m.created_at,m.sender_id,IF(m.sender_id=t.customer_id,"Customer","Driver") sender FROM rs_messages m JOIN rs_trips t ON t.id=m.trip_id WHERE m.trip_id=? ORDER BY m.id LIMIT 100',[$trip['id']]);
 if($u['id']!==(int)$trip['customer_id']&&$u['id']!==(int)$trip['driver_id'])$result['messages']=[];
 if($trip['driver_id']&&!in_array($trip['status'],TERMINAL_TRIPS,true)){$d=row('SELECT heartbeat_at,location_json FROM rs_drivers WHERE user_id=?',[$trip['driver_id']]);$result['driver_location']=decode($d['location_json']);$result['location_fresh']=fresh_driver_location($d);if($u['id']===(int)$trip['customer_id']&&$result['location_fresh']&&in_array($trip['status'],['assigned','driver_arriving'])){try{$approach=road_route([$result['driver_location'],$snapshot['pickup']],$snapshot['product']['key']);$result['pickup_eta_seconds']=$approach['duration_seconds'];}catch(HttpFailure $e){$result['pickup_eta_seconds']=null;}}$result['driver_reachable']=$d['heartbeat_at']&&strtotime($d['heartbeat_at'])>time()-60;}
 $result['remaining_fare_minor']=max(0,(int)sql('SELECT COALESCE(SUM(e.amount_minor),0) FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE j.trip_id=? AND e.account_key="customer_receivable"',[$trip['id']])->fetchColumn());
 $result['adjustments']=rows('SELECT j.kind,IF(j.kind="fare_adjustment",-e.amount_minor,e.amount_minor) amount_minor,j.created_at FROM rs_journals j JOIN rs_entries e ON e.journal_id=j.id WHERE j.trip_id=? AND e.account_key IN ("refund_expense","fare_adjustment") ORDER BY j.created_at',[$trip['id']]);
$review=row('SELECT accepted_fare_minor,final_fare_minor,earning_minor,billable_distance_m,created_at FROM rs_fare_reviews WHERE trip_id=?',[$trip['id']]);$result['fare_review']=$review;
 $result['fare_items']=[['label'=>'Distance × accepted rate','amount_minor'=>$snapshot['base_fare_minor']],['label'=>'Promotion','amount_minor'=>-($snapshot['discount_minor']??0)]];
 if($review)$result['fare_items'][]=['label'=>'Reviewed interruption reduction','amount_minor'=>(int)$trip['fare_minor']-(int)$snapshot['fare_minor']];
 $tip=row('SELECT id FROM rs_journals WHERE reference_key=?',['tip:'.$trip['id']]);if($tip){$result['tip_minor']=tip_total($trip['id']);$result['tip_status']=row('SELECT id FROM rs_journals WHERE reference_key=?',['tip-confirmed:'.$trip['id']])?'received':($result['tip_minor']?'declared_pending':'cancelled');}
 if(($u['id']===(int)$trip['driver_id']&&in_array($trip['status'],TERMINAL_TRIPS,true))||(!$staffReveal&&$u['id']!==(int)$trip['customer_id']&&$u['id']!==(int)$trip['driver_id'])){
  foreach(['pickup','destination'] as $key){$result['snapshot'][$key]['name']='Dhaka area';$result['snapshot'][$key]['address']='Dhaka area';$result['snapshot'][$key]['lat']=round((float)$snapshot[$key]['lat'],2);$result['snapshot'][$key]['lng']=round((float)$snapshot[$key]['lng'],2);}
  $result['snapshot']['stops']=array_map(function($p){$p['name']='Dhaka area';$p['address']='Dhaka area';$p['lat']=round((float)$p['lat'],2);$p['lng']=round((float)$p['lng'],2);return $p;},$snapshot['stops']);$result['snapshot']['route']=array_map(fn($p)=>['lat'=>round((float)$p['lat'],2),'lng'=>round((float)$p['lng'],2)],$snapshot['route']);unset($result['snapshot']['note'],$result['snapshot']['profile_id'],$result['snapshot']['customer_label']);$result['events']=array_map(function($e){$e['details']='{}';return $e;},$result['events']);$result['pending_change']=null;unset($result['driver_location']);
 }
 if($u['id']!==(int)$trip['customer_id']&&$u['id']!==(int)$trip['driver_id'])unset($result['snapshot']['customer_label'],$result['snapshot']['note'],$result['snapshot']['profile_id']);
 if(permitted($u,'trips')&&$u['id']!==(int)$trip['customer_id']&&$u['id']!==(int)$trip['driver_id'])audit($u['id'],'trip.read',$trip['id'],'Scoped operational trip detail');
 return $result;
}
function driver_readiness(int $id,?int $product=null,bool $lock=false):array {
 $d=row('SELECT d.*,u.status account_status FROM rs_drivers d JOIN rs_users u ON u.id=d.user_id WHERE d.user_id=?'.($lock?' FOR UPDATE':''),[$id]);$reasons=[];
 if(!$d)return ['ready'=>false,'reasons'=>['Complete driver enrollment.']];
 if(!in_array('driver',roles_for($id),true))$reasons[]='An active approved driver role is required.';
 if($d['account_status']!=='active')$reasons[]='Account access is restricted.';
 if($d['status']!=='approved')$reasons[]=$d['reason']?:'Driver application requires review.';
 if($d['identity_status']!=='approved')$reasons[]='Complete the identity review.';
 if($d['rest_until']&&strtotime($d['rest_until'])>time())$reasons[]='Required rest ends at '.$d['rest_until'].' UTC.';
 $ops=config('operations');$work=(int)$d['work_seconds']+($d['online_since']?max(0,time()-strtotime($d['online_since'])):0);
 if($d['rest_until']&&strtotime($d['rest_until'])<=time())$work=0;
 if($work>=(int)$ops['work_limit_seconds'])$reasons[]='End the session and complete the required rest.';
 $v=$d['active_vehicle_id']?row('SELECT * FROM rs_vehicles WHERE id=? AND driver_id=?'.($lock?' FOR UPDATE':''),[$d['active_vehicle_id'],$id]):null;
 if(!$v||$v['status']!=='approved')$reasons[]='Choose an approved vehicle.';
 if($v&&$product!==null&&(int)$v['product_id']!==$product)$reasons[]='The selected vehicle is incompatible with this product.';
 if($v){foreach(['license','registration','insurance'] as $kind)if(!row('SELECT id FROM rs_documents WHERE user_id=? AND vehicle_id=? AND kind=? AND status="approved" AND expires_at>UTC_TIMESTAMP() AND (scan_status="clean" OR (storage_key LIKE "fixture-%" AND ?=1))'.($lock?' FOR UPDATE':''),[$id,$v['id'],$kind,getenv('APP_ENV')==='local']))$reasons[]='Current '.$kind.' evidence requires review.';$p=row('SELECT requirements FROM rs_products WHERE id=?',[$v['product_id']]);$equipment=decode($v['equipment']);foreach(decode($p['requirements']) as $key=>$required)if($required&&!($equipment[$key]??false))$reasons[]='Required '.$key.' equipment is not recorded.';}
 return ['ready'=>!$reasons,'reasons'=>$reasons,'profile'=>$d,'vehicle'=>$v,'work_seconds'=>$work,'work_limit_seconds'=>$ops['work_limit_seconds'],'work_warning_seconds'=>(int)($ops['work_warning_seconds']??900)];
}
function fresh_driver_location(array $driver):bool {
 $p=decode($driver['location_json']??null);if(!$p||strtotime($p['observed_at']??'1970-01-01')<time()-60||($p['accuracy']??1001)>150)return false;
 $market=config('market');return distance_m((float)$p['lat'],(float)$p['lng'],(float)$market['center_lat'],(float)$market['center_lng'])<=(float)$market['radius_km']*1000;
}
function dispatch_trip(array $trip):void {
 if($trip['status']!=='matching'||config('operations')['matching_paused'])return;
 $snapshot=decode($trip['snapshot']);$ops=config('operations');
 $candidates=rows('SELECT d.user_id FROM rs_drivers d JOIN rs_users u ON u.id=d.user_id JOIN rs_vehicles v ON v.id=d.active_vehicle_id WHERE u.status="active" AND d.status="approved" AND d.desired_online=1 AND d.heartbeat_at>DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? SECOND) AND v.product_id=? AND d.user_id<>? AND NOT EXISTS(SELECT 1 FROM rs_active a WHERE a.actor_type="driver" AND a.actor_id=d.user_id) AND NOT EXISTS(SELECT 1 FROM rs_exclusions e WHERE e.customer_id=? AND e.driver_id=d.user_id AND e.revoked_at IS NULL AND e.expires_at>UTC_TIMESTAMP()) AND NOT EXISTS(SELECT 1 FROM rs_offers o WHERE o.trip_id=? AND o.driver_id=d.user_id) ORDER BY d.heartbeat_at DESC LIMIT 10',[$ops['heartbeat_seconds'],$snapshot['product']['id'],$trip['customer_id'],$trip['customer_id'],$trip['id']]);
 foreach($candidates as $candidate){$ready=driver_readiness((int)$candidate['user_id'],(int)$snapshot['product']['id']);if(!$ready['ready']||!fresh_driver_location($ready['profile']))continue;$id=identifier();$insert=sql('INSERT IGNORE INTO rs_offers(id,trip_id,driver_id,vehicle_id,expires_at) VALUES(?,?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL ? SECOND))',[$id,$trip['id'],$candidate['user_id'],$ready['vehicle']['id'],$ops['offer_seconds']]);if($insert->rowCount())notify((int)$candidate['user_id'],'offer','New ride request',$snapshot['pickup']['name'].' → '.$snapshot['destination']['name'],$trip['id']);}
}
function housekeeping():void {
 sql('UPDATE rs_offers SET status="expired" WHERE status="pending" AND expires_at<=UTC_TIMESTAMP()');
 foreach(rows('SELECT id FROM rs_trips WHERE status="matching" ORDER BY created_at LIMIT 30') as $candidate)transaction(function()use($candidate){$trip=trip_row($candidate['id'],true);if($trip['status']!=='matching')return [];if(strtotime($trip['created_at'])<time()-180){sql('UPDATE rs_trips SET status="no_driver",ended_at=UTC_TIMESTAMP(),version=version+1 WHERE id=?',[$trip['id']]);release_trip($trip);notify((int)$trip['customer_id'],'trip','No driver found','Try another vehicle or request a fresh quote.',$trip['id']);}else dispatch_trip($trip);return [];});
}
function release_trip(array $trip):void {sql('DELETE FROM rs_active WHERE trip_id=?',[$trip['id']]);sql('UPDATE rs_offers SET status="expired" WHERE trip_id=? AND status="pending"',[$trip['id']]);}
function journal(array $u,string $kind,string $reference,?string $trip,array $entries,?string $evidence=null):void {
 if(array_sum(array_column($entries,'amount'))!==0)fail(500,'Financial journal is unbalanced.');if(row('SELECT id FROM rs_journals WHERE reference_key=?',[$reference]))return;
 $id=identifier();sql('INSERT INTO rs_journals(id,trip_id,kind,reference_key,actor_id,evidence) VALUES(?,?,?,?,?,?)',[$id,$trip,$kind,$reference,$u['id'],$evidence]);foreach($entries as $e)sql('INSERT INTO rs_entries(journal_id,account_key,user_id,amount_minor) VALUES(?,?,?,?)',[$id,$e['account'],$e['user']??null,$e['amount']]);
}
function trip_action(string $action,array $b,array $u):?array {
 if(in_array($action,['tip','tip-change','confirm-tip','rate-trip']))return post_trip_action($action,$b,$u);
 if($action==='places'){return ['places'=>array_map('place_view',rows('SELECT * FROM rs_places WHERE active=1 AND (name LIKE ? OR address LIKE ?) ORDER BY id LIMIT 30',['%'.text_value($_GET['q']??'',100).'%','%'.text_value($_GET['q']??'',100).'%']))];}
 if($action==='quote'){
  permit($u,'customer');marketplace_user($u);$p=row('SELECT * FROM rs_products WHERE id=? AND active=1',[(int)($b['product_id']??0)]);if(!$p||config('operations')['matching_paused'])fail(409,'This service is currently unavailable.');
  $pickup=validate_place($b['pickup']??[]);$destination=validate_place($b['destination']??[]);$stops=[];foreach($b['stops']??[] as $stop)$stops[]=validate_place($stop);if(count($stops)>(int)config('operations')['max_stops'])fail(422,'Too many stops.');
  $needs=$b['needs']??[];$passengers=(int)($needs['passengers']??1);if($passengers<1||$passengers>(int)$p['capacity'])fail(422,'Passenger count exceeds this vehicle capacity.');
  $requirements=decode($p['requirements']);if(!empty($needs['wheelchair']))fail(422,'No reviewed wheelchair-accessible supply is configured. Choose supported transport or contact Help.');
  if($p['product_key']==='bike'&&empty($needs['helmet_confirmed']))fail(422,'Confirm a passenger helmet is required before booking Bike.');
  $path=array_merge([$pickup],$stops,[$destination]);$routing=road_route($path,$p['product_key']);$meters=$routing['distance_m'];$source=$routing['source'];
  $base=(int)(round($meters*(int)$p['rate_minor']/100000)*100);$discount=0;$promoId=null;
  if(!empty($b['promo'])){if(!feature_enabled($u,'promotions'))fail(422,'Promotions are not available to this account cohort.');$promo=row('SELECT * FROM rs_promos WHERE code=? AND active=1 AND expires_at>UTC_TIMESTAMP()',[strtoupper(text_value($b['promo'],32))]);if(!$promo||row('SELECT trip_id FROM rs_redemptions WHERE promo_id=? AND user_id=?',[$promo['id'],$u['id']])||(int)sql('SELECT COUNT(*) FROM rs_redemptions WHERE promo_id=?',[$promo['id']])->fetchColumn()>=(int)$promo['maximum_uses'])fail(422,'This promotion is not eligible.');$promoId=$promo['id'];$discount=min($base,(int)$promo['discount_minor']);}
  $terms=row('SELECT * FROM rs_terms WHERE kind="service" AND effective_at<=UTC_TIMESTAMP() ORDER BY effective_at DESC,id DESC LIMIT 1');$id=identifier();
  sql('INSERT INTO rs_quotes(id,customer_id,product_id,pickup,destination,stops,needs,distance_m,duration_seconds,route_source,route_json,rate_minor,fare_minor,discount_minor,product_version,terms_id,promo_id,expires_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL 5 MINUTE))',[$id,$u['id'],$p['id'],j($pickup),j($destination),j($stops),j($needs),$meters,$routing['duration_seconds'],$source,j($routing['route']),$p['rate_minor'],$base-$discount,$discount,$p['version'],$terms['id'],$promoId]);
  return ['quote'=>row('SELECT * FROM rs_quotes WHERE id=?',[$id]),'product'=>$p,'route_duration_seconds'=>$routing['duration_seconds'],'terms'=>$terms,'terms_accepted'=>(bool)row('SELECT id FROM rs_consents WHERE user_id=? AND terms_id=? AND withdrawn_at IS NULL',[$u['id'],$terms['id']])];
 }
 if($action==='request-trip'){
  permit($u,'customer');marketplace_user($u);if(row('SELECT trip_id FROM rs_active WHERE actor_type IN ("customer","driver") AND actor_id=?',[$u['id']]))fail(409,'You already have an active trip. Open it from Home.');
  $quote=row('SELECT q.*,p.name,p.product_key,p.capacity,p.driver_share_bps,p.active,p.version current_version FROM rs_quotes q JOIN rs_products p ON p.id=q.product_id WHERE q.id=? AND q.customer_id=? AND q.expires_at>UTC_TIMESTAMP() FOR UPDATE',[required($b,'quote_id',32),$u['id']]);
  if(!$quote)fail(409,'Your quote expired. Review a fresh price.');if(!$quote['active']||$quote['product_version']!=$quote['current_version']||config('operations')['matching_paused'])fail(409,'Availability or pricing changed. Review a fresh quote.');
  $currentTerms=row('SELECT id FROM rs_terms WHERE kind="service" AND effective_at<=UTC_TIMESTAMP() ORDER BY effective_at DESC,id DESC LIMIT 1');
  if((int)$currentTerms['id']!==(int)$quote['terms_id'])fail(409,'Service terms changed. Review a fresh quote and the updated terms.');
  if(!empty($b['accept_terms'])&&(int)($b['terms_id']??0)===(int)$quote['terms_id']){sql('INSERT INTO rs_consents(user_id,terms_id) VALUES(?,?) ON DUPLICATE KEY UPDATE withdrawn_at=NULL,accepted_at=UTC_TIMESTAMP()',[$u['id'],$quote['terms_id']]);audit($u['id'],'consent.accepted',(string)$quote['terms_id'],'Customer accepted the displayed quote terms');}
  if(!row('SELECT id FROM rs_consents WHERE user_id=? AND terms_id=? AND withdrawn_at IS NULL',[$u['id'],$quote['terms_id']]))fail(422,'Accept the current service terms before booking.');
  if($u['contact_status']==='unverified'&&config('market')['real_operations'])fail(403,'Complete contact verification first.');
  if($quote['promo_id']){if(row('SELECT trip_id FROM rs_redemptions WHERE promo_id=? AND user_id=?',[$quote['promo_id'],$u['id']]))fail(409,'This promotion was already used.');$promo=row('SELECT * FROM rs_promos WHERE id=? AND active=1 AND expires_at>UTC_TIMESTAMP() FOR UPDATE',[$quote['promo_id']]);if(!$promo||(int)sql('SELECT COUNT(*) FROM rs_redemptions WHERE promo_id=?',[$promo['id']])->fetchColumn()>=(int)$promo['maximum_uses'])fail(409,'This promotion is no longer available.');}
  $id=identifier();$pin=str_pad((string)random_int(0,9999),4,'0',STR_PAD_LEFT);$snapshot=['pickup'=>decode($quote['pickup']),'destination'=>decode($quote['destination']),'stops'=>decode($quote['stops']),'needs'=>decode($quote['needs']),'customer_label'=>$u['name'],'product'=>['id'=>(int)$quote['product_id'],'name'=>$quote['name'],'key'=>$quote['product_key'],'capacity'=>(int)$quote['capacity']],'route_duration_seconds'=>(int)$quote['duration_seconds'],'distance_m'=>(int)$quote['distance_m'],'route_source'=>$quote['route_source'],'route'=>decode($quote['route_json']),'rate_minor'=>(int)$quote['rate_minor'],'base_fare_minor'=>(int)$quote['fare_minor']+(int)$quote['discount_minor'],'discount_minor'=>(int)$quote['discount_minor'],'fare_minor'=>(int)$quote['fare_minor'],'driver_share_bps'=>(int)$quote['driver_share_bps'],'terms_id'=>(int)$quote['terms_id'],'note'=>text_value($b['note']??'',240),'profile_id'=>$b['profile_id']??null];
  if($snapshot['profile_id']&&!row('SELECT id FROM rs_profiles WHERE id=? AND user_id=?',[$snapshot['profile_id'],$u['id']]))fail(403,'Travel profile does not belong to your account.');
  sql('INSERT INTO rs_trips(id,customer_id,quote_id,status,snapshot,fare_minor,pin_hash,pin_encrypted,pin_required) VALUES(?,?,?,"matching",?,?,?,?,?)',[$id,$u['id'],$quote['id'],j($snapshot),$quote['fare_minor'],password_hash($pin,PASSWORD_DEFAULT),encrypt_value($pin),!empty($u['preferences']['pin_enabled'])]);
  sql('INSERT INTO rs_active(actor_type,actor_id,trip_id) VALUES("customer",?,?)',[$u['id'],$id]);if($quote['promo_id'])sql('INSERT INTO rs_redemptions(promo_id,user_id,trip_id) VALUES(?,?,?)',[$quote['promo_id'],$u['id'],$id]);
  $trip=trip_row($id);event($trip,$u,'requested',['quote_id'=>$quote['id']]);dispatch_trip($trip);return ['ok'=>true,'trip_id'=>$id];
 }
 if($action==='trip'){$id=required($_GET,'id',32);$grant=permitted($u,'trips')&&(bool)row('SELECT trip_id FROM rs_trip_reveals WHERE session_id=? AND trip_id=? AND actor_id=? AND expires_at>UTC_TIMESTAMP()',[$u['session_id'],$id,$u['id']]);return ['trip'=>trip_view(trip_row($id),$u,$grant)];}
 if($action==='history'){
  $scope=($_GET['scope']??'customer')==='driver'?'driver':'customer';permit($u,$scope);$column=$scope.'_id';$offset=max(0,(int)($_GET['offset']??0));$search='%'.text_value($_GET['q']??'',100).'%';
  $list=rows("SELECT * FROM rs_trips WHERE {$column}=? AND (id LIKE ? OR JSON_UNQUOTE(JSON_EXTRACT(snapshot,'$.destination.name')) LIKE ?) ORDER BY created_at DESC LIMIT 20 OFFSET {$offset}",[$u['id'],$search,$search]);
  return ['trips'=>array_map(fn($t)=>trip_view($t,$u),$list),'next_offset'=>count($list)===20?$offset+20:null,'total'=>(int)sql("SELECT COUNT(*) FROM rs_trips WHERE {$column}=?",[$u['id']])->fetchColumn()];
 }
 if($action==='offer'){
  permit($u,'driver');marketplace_user($u);$offer=row('SELECT * FROM rs_offers WHERE id=? AND driver_id=? FOR UPDATE',[required($b,'id',32),$u['id']]);if(!$offer||$offer['status']!=='pending'||strtotime($offer['expires_at'])<=time())fail(409,'This offer is no longer available.');
  $trip=trip_row($offer['trip_id'],true);if($trip['status']!=='matching')fail(409,'This ride was already accepted or ended.');
  if(($b['decision']??'')==='decline'){sql('UPDATE rs_offers SET status="declined" WHERE id=?',[$offer['id']]);event($trip,$u,'offer_declined');return ['ok'=>true];}
  if(($b['decision']??'')!=='accept')fail(422,'Choose accept or decline.');
  $ready=driver_readiness($u['id'],(int)decode($trip['snapshot'])['product']['id'],true);$d=$ready['profile']??[];
  if(!$ready['ready']||!fresh_driver_location($d)||!$d['desired_online']||!$d['heartbeat_at']||strtotime($d['heartbeat_at'])<time()-(int)config('operations')['heartbeat_seconds'])fail(409,'Your driver readiness changed. Refresh and resolve the blockers.');
  if((int)$d['active_vehicle_id']!==(int)$offer['vehicle_id']||row('SELECT actor_id FROM rs_active WHERE actor_type IN ("customer","driver") AND actor_id=?',[$u['id']]))fail(409,'This driver or vehicle is already assigned.');
  if(row('SELECT customer_id FROM rs_exclusions WHERE customer_id=? AND driver_id=? AND revoked_at IS NULL AND expires_at>UTC_TIMESTAMP()',[$trip['customer_id'],$u['id']]))fail(409,'This pairing is not eligible.');
  $p=row('SELECT active,version FROM rs_products WHERE id=?',[(int)decode($trip['snapshot'])['product']['id']]);if(!$p['active']||config('operations')['matching_paused'])fail(409,'Matching is paused for this product.');
  $snapshot=decode($trip['snapshot']);$snapshot['driver']=['name'=>$u['name'],'vehicle'=>$ready['vehicle']['label'],'plate'=>$ready['vehicle']['plate'],'vehicle_id'=>(int)$ready['vehicle']['id'],'make'=>$ready['vehicle']['make'],'model'=>$ready['vehicle']['model'],'color'=>$ready['vehicle']['color'],'photo_document_id'=>row('SELECT id FROM rs_documents WHERE user_id=? AND kind="profile_photo" AND status="approved" AND scan_status="clean" ORDER BY id DESC LIMIT 1',[$u['id']])['id']??null];
  sql('INSERT INTO rs_active(actor_type,actor_id,trip_id) VALUES("driver",?,?),("vehicle",?,?)',[$u['id'],$trip['id'],$offer['vehicle_id'],$trip['id']]);
  sql('UPDATE rs_trips SET driver_id=?,vehicle_id=?,snapshot=?,status="assigned",accepted_at=UTC_TIMESTAMP(),version=version+1 WHERE id=?',[$u['id'],$offer['vehicle_id'],j($snapshot),$trip['id']]);sql('UPDATE rs_offers SET status=IF(id=?,"accepted","expired") WHERE trip_id=?',[$offer['id'],$trip['id']]);event($trip,$u,'driver_accepted');notify((int)$trip['customer_id'],'trip','Driver accepted','Check the vehicle details before pickup.',$trip['id']);return ['ok'=>true,'trip_id'=>$trip['id']];
 }
 if($action==='driver-trip'){
  permit_current_driver($u);$trip=trip_row(required($b,'trip_id',32),true);if((int)$trip['driver_id']!==$u['id'])fail(403,'Only the assigned driver can operate this trip.');version_guard($trip,$b);$next=required($b,'next',24);
  $states=['head'=>['assigned','driver_arriving'],'arrive'=>['driver_arriving','arrived'],'start'=>['arrived','in_progress'],'complete'=>['in_progress','completed']];
  if(!isset($states[$next])||$trip['status']!==$states[$next][0])fail(409,'The trip changed. Refresh its current stage.');
  if($next==='complete'){$s=decode($trip['snapshot']);$visited=(int)(row('SELECT completed_stops FROM rs_trip_progress WHERE trip_id=?',[$trip['id']])['completed_stops']??0);if($visited<count($s['stops']))fail(409,'Confirm each authorized stop before completing the ride, or use interrupted-trip assistance if it ended early.');}
  if($next==='arrive'){
   $d=row('SELECT location_json FROM rs_drivers WHERE user_id=?',[$u['id']]);$p=decode($d['location_json']);$pickup=decode($trip['snapshot'])['pickup'];$near=fresh_driver_location($d)&&distance_m((float)$p['lat'],(float)$p['lng'],(float)$pickup['lat'],(float)$pickup['lng'])<=200;
   if(!$near)fail(409,'Arrival needs a recent accurate device observation near the confirmed pickup. Check your location or contact support for pickup recovery.');
   event($trip,$u,'arrival_evidence',['source'=>'device','accuracy'=>$p['accuracy'],'observed_at'=>$p['observed_at']]);
  }
  if($next==='start'){
   if((int)$trip['pin_attempts']>=5)fail(429,'PIN attempts are exhausted. Contact trip support for a reviewed recovery.');
   if($trip['pin_required']&&!password_verify(text_value($b['pin']??'',4),$trip['pin_hash'])){sql('UPDATE rs_trips SET pin_attempts=pin_attempts+1 WHERE id=?',[$trip['id']]);event($trip,$u,'pin_rejected');return ['error'=>'The PIN does not match. Ask the customer to check their trip PIN.','http_status'=>422];}
   $ready=driver_readiness($u['id'],(int)decode($trip['snapshot'])['product']['id'],true);if(!$ready['ready'])fail(409,'Starting is restricted. Contact support for a safe recovery.');
  }
  $target=$states[$next][1];sql('UPDATE rs_trips SET status=?,arrived_at=IF(?="arrived",UTC_TIMESTAMP(),arrived_at),started_at=IF(?="in_progress",UTC_TIMESTAMP(),started_at),ended_at=IF(?="completed",UTC_TIMESTAMP(),ended_at),version=version+1 WHERE id=?',[$target,$target,$target,$target,$trip['id']]);event($trip,$u,'driver_'.$next);
  if($next==='complete'){
   $snapshot=decode($trip['snapshot']);$earning=(int)round((int)$snapshot['base_fare_minor']*(int)$snapshot['driver_share_bps']/10000);sql('UPDATE rs_trips SET earning_minor=? WHERE id=?',[$earning,$trip['id']]);
   journal($u,'fare','fare:'.$trip['id'],$trip['id'],[['account'=>'customer_receivable','user'=>(int)$trip['customer_id'],'amount'=>(int)$trip['fare_minor']],['account'=>'fare_revenue','amount'=>-(int)$trip['fare_minor']]]);
   journal($u,'earning','earning:'.$trip['id'],$trip['id'],[['account'=>'driver_cost','amount'=>$earning],['account'=>'driver_payable','user'=>$u['id'],'amount'=>-$earning]]);release_trip($trip);
  }
  notify((int)$trip['customer_id'],'trip','Trip '.str_replace('_',' ',$target),'Open your trip for the latest details.',$trip['id']);return ['ok'=>true,'status'=>$target];
 }
 if($action==='cancel-trip'){
  permit($u,'customer');$trip=trip_row(required($b,'trip_id',32),true);if((int)$trip['customer_id']!==$u['id'])fail(403,'Only the booking customer can cancel.');version_guard($trip,$b);
  if(in_array($trip['status'],TERMINAL_TRIPS,true)||$trip['status']==='in_progress')fail(409,'This trip cannot be cancelled. Use trip Help for an interruption.');
  sql('UPDATE rs_trips SET status="cancelled",ended_at=UTC_TIMESTAMP(),version=version+1 WHERE id=?',[$trip['id']]);release_trip($trip);event($trip,$u,'customer_cancelled',['reason'=>required($b,'reason',240),'fee_minor'=>0]);if($trip['driver_id'])notify((int)$trip['driver_id'],'trip','Trip cancelled','The customer cancelled before start.',$trip['id']);return ['ok'=>true];
 }
 if($action==='driver-cancel'){
  permit_current_driver($u);$trip=trip_row(required($b,'trip_id',32),true);if((int)$trip['driver_id']!==$u['id'])fail(403,'Only the assigned driver can cancel.');version_guard($trip,$b);if(!in_array($trip['status'],['assigned','driver_arriving','arrived']))fail(409,'Use interrupted-trip help for an active ride.');
  sql('DELETE FROM rs_active WHERE trip_id=? AND actor_type IN ("driver","vehicle")',[$trip['id']]);$snapshot=decode($trip['snapshot']);unset($snapshot['driver']);sql('UPDATE rs_trips SET status="matching",driver_id=NULL,vehicle_id=NULL,snapshot=?,created_at=UTC_TIMESTAMP(),version=version+1 WHERE id=?',[j($snapshot),$trip['id']]);event($trip,$u,'driver_cancelled',['reason'=>required($b,'reason',240)]);notify((int)$trip['customer_id'],'trip','Driver cancelled','Matching continues. You can cancel without a fee.',$trip['id']);return ['ok'=>true];
 }
 if($action==='interrupt-trip'){
  permit_current_driver($u);$trip=trip_row(required($b,'trip_id',32),true);if((int)$trip['driver_id']!==$u['id'])fail(403,'Only the assigned driver can interrupt this trip.');version_guard($trip,$b);if($trip['status']!=='in_progress')fail(409,'Only an active ride can be interrupted.');$reason=required($b,'reason',500);
  sql('UPDATE rs_trips SET status="interrupted",ended_at=UTC_TIMESTAMP(),payment_status="under_review",version=version+1 WHERE id=?',[$trip['id']]);sql('UPDATE rs_drivers SET desired_online=0,status="review",reason=?,version=version+1 WHERE user_id=?',['Resolve the interrupted-trip vehicle review.',$u['id']]);sql('UPDATE rs_vehicles SET status="review" WHERE id=?',[$trip['vehicle_id']]);release_trip($trip);$loc=decode(row('SELECT location_json FROM rs_drivers WHERE user_id=?',[$u['id']])['location_json']);event($trip,$u,'interrupted',['reason'=>$reason,'last_device_observation'=>$loc?:null,'location_current'=>$loc&&strtotime($loc['observed_at'])>time()-60]);$id=identifier();sql('INSERT INTO rs_cases(id,user_id,trip_id,category,subject,priority,due_at) VALUES(?,?,?,"assistance","Interrupted-trip assistance","urgent",DATE_ADD(UTC_TIMESTAMP(),INTERVAL 15 MINUTE))',[$id,$trip['customer_id'],$trip['id']]);sql('INSERT INTO rs_case_messages(case_id,actor_id,body) VALUES(?,?,?)',[$id,$u['id'],$reason]);notify((int)$trip['customer_id'],'safety','Trip interrupted','An assistance case was created. This does not dispatch emergency responders.',$id);return ['ok'=>true,'case_id'=>$id];
 }
 if($action==='trip-message'){
  $trip=trip_row(required($b,'trip_id',32));participant($u,$trip);if(in_array($trip['status'],TERMINAL_TRIPS,true))fail(409,'Use trip-linked Help after the ride ends.');$message=required($b,'message',2000);sql('INSERT INTO rs_messages(trip_id,sender_id,body) VALUES(?,?,?)',[$trip['id'],$u['id'],$message]);$to=$u['id']===(int)$trip['customer_id']?$trip['driver_id']:$trip['customer_id'];if($to)notify((int)$to,'trip','New trip message','Open your trip conversation.',$trip['id']);return ['ok'=>true];
 }
 if($action==='collect-cash'){
  permit($u,'driver');$trip=trip_row(required($b,'trip_id',32),true);if((int)$trip['driver_id']!==$u['id'])fail(403,'Only the assigned driver records collection.');if($trip['status']!=='completed'||$trip['payment_status']!=='uncollected')fail(409,'This collection is not pending.');$amount=(int)($b['amount_minor']??-1);if($amount!==(int)$trip['fare_minor'])fail(422,'Record exactly the amount on the receipt. Partial or disputed amounts need staff review.');$evidence=required($b,'evidence',500);
  journal($u,'cash_collection','cash:'.$trip['id'],$trip['id'],[['account'=>'driver_cash_held','user'=>$u['id'],'amount'=>$amount],['account'=>'customer_receivable','user'=>(int)$trip['customer_id'],'amount'=>-$amount]],$evidence);sql('UPDATE rs_trips SET payment_status="collection_reported",version=version+1 WHERE id=?',[$trip['id']]);notify((int)$trip['customer_id'],'payment','Cash collection recorded','Confirm the recorded cash amount or open a dispute.',$trip['id']);return ['ok'=>true];
 }
 if($action==='confirm-cash'){
  permit($u,'customer');$trip=trip_row(required($b,'trip_id',32),true);if((int)$trip['customer_id']!==$u['id'])fail(403,'Only the customer confirms their collection.');if($trip['payment_status']!=='collection_reported')fail(409,'There is no recorded collection to confirm.');$offset=min((int)$trip['fare_minor'],(int)$trip['earning_minor']);if($offset)journal($u,'cash_earning_offset','cash-offset:'.$trip['id'],$trip['id'],[['account'=>'driver_payable','user'=>(int)$trip['driver_id'],'amount'=>$offset],['account'=>'driver_cash_held','user'=>(int)$trip['driver_id'],'amount'=>-$offset]],'Customer confirmed the cash collection; cash retained offsets driver payable.');sql('UPDATE rs_trips SET payment_status="collected",version=version+1 WHERE id=?',[$trip['id']]);event($trip,$u,'cash_confirmed');return ['ok'=>true];
 }
 if($action==='share-trip'){
  $trip=trip_row(required($b,'trip_id',32));participant($u,$trip);if(in_array($trip['status'],TERMINAL_TRIPS,true))fail(409,'Only active trips can be shared.');$token=bin2hex(random_bytes(32));sql('INSERT INTO rs_shares(token_hash,trip_id,created_by,expires_at) VALUES(?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL 2 HOUR))',[hash('sha256',$token),$trip['id'],$u['id']]);return ['ok'=>true,'path'=>'/shared.php?token='.$token];
 }
 if($action==='revoke-share'){sql('UPDATE rs_shares SET revoked_at=UTC_TIMESTAMP() WHERE trip_id=? AND created_by=?',[required($b,'trip_id',32),$u['id']]);return ['ok'=>true];}
 return null;
}
