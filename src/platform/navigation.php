<?php
declare(strict_types=1);
function navigation_action(string $action,array $b,array $u):?array {
 if(!in_array($action,['navigation','driver-stop']))return null;
 permit_current_driver($u);$id=$action==='navigation'?required($_GET,'id',32):required($b,'trip_id',32);$trip=trip_row($id,$action==='driver-stop');
 if((int)$trip['driver_id']!==$u['id'])fail(403,'Only the assigned driver can navigate or confirm stops.');
 if(in_array($trip['status'],TERMINAL_TRIPS))fail(409,'This trip has ended.');
 $s=decode($trip['snapshot']);$driver=row('SELECT location_json FROM rs_drivers WHERE user_id=?',[$u['id']]);if(!fresh_driver_location($driver))fail(409,'A fresh accurate location is required. The accepted itinerary remains available on your trip.');$p=decode($driver['location_json']);
 $done=(int)(row('SELECT completed_stops FROM rs_trip_progress WHERE trip_id=?',[$id])['completed_stops']??0);
 if($action==='driver-stop'){
  version_guard($trip,$b);if($trip['status']!=='in_progress'||(int)($b['index']??-1)!==$done||!isset($s['stops'][$done]))fail(409,'Confirm only the next authorized stop on an active trip.');$stop=$s['stops'][$done];if(distance_m((float)$p['lat'],(float)$p['lng'],(float)$stop['lat'],(float)$stop['lng'])>200)fail(409,'Confirm a stop only after reaching its location.');
  sql('INSERT INTO rs_trip_progress(trip_id,completed_stops) VALUES(?,?) ON DUPLICATE KEY UPDATE completed_stops=VALUES(completed_stops)',[$id,$done+1]);sql('UPDATE rs_trips SET version=version+1 WHERE id=?',[$id]);event($trip,$u,'stop_visited',['index'=>$done,'source'=>'device','accuracy'=>$p['accuracy']]);notify((int)$trip['customer_id'],'trip','Stop confirmed',$stop['name'],$id);return ['ok'=>true];
 }
 $places=$trip['status']==='in_progress'?array_merge([$p],array_slice($s['stops'],$done),[$s['destination']]):[$p,$s['pickup']];
 return ['navigation'=>road_route($places,$s['product']['key'],true),'target'=>$trip['status']==='in_progress'?'Remaining authorized itinerary':'Confirmed pickup','policy'=>'Navigation estimate uses local road data without live traffic. It does not change the accepted fare. Read instructions only when safe; road signs and conditions take precedence.'];
}
