<?php
declare(strict_types=1);
require __DIR__.'/../src/platform/core.php';require __DIR__.'/../src/platform/trips.php';
if(PHP_SAPI!=='cli')exit(1);
$policy=config('retention');if(empty($policy['approved_request'])||!row('SELECT id FROM rs_requests WHERE id=? AND kind="retention_policy" AND status="executed"',[$policy['approved_request']]))throw new RuntimeException('An independently approved retention policy is required.');
$apply=in_array('--apply',$argv,true);$summary=['mode'=>$apply?'apply':'dry_run','policy'=>$policy['approved_request'],'trip_locations'=>0,'closed_case_messages'=>0,'private_files'=>0,'files_removed'=>0,'driver_locations'=>0,'expired_sessions'=>0];
$held=fn(int $user)=>(bool)row('SELECT id FROM rs_legal_holds WHERE user_id=? AND released_at IS NULL AND expires_at>UTC_TIMESTAMP()',[$user]);
$lockUsers=function(array $ids)use($held):bool{$ids=array_values(array_unique(array_filter($ids)));sort($ids,SORT_NUMERIC);foreach($ids as $id){sql('SELECT id FROM rs_users WHERE id=? FOR UPDATE',[$id]);if($held($id))return false;}return true;};
foreach(rows('SELECT * FROM rs_trips WHERE ended_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? DAY) AND status IN ("completed","cancelled","no_driver","interrupted","no_show") LIMIT 100',[$policy['trip_location_days']]) as $t){
 $ids=[(int)$t['customer_id'],(int)$t['driver_id']];if(array_filter(array_filter($ids),$held)||row('SELECT id FROM rs_cases WHERE trip_id=? AND status<>"resolved"',[$t['id']]))continue;
 $s=decode($t['snapshot']);if(isset($s['location_purged_at']))continue;
 foreach(['pickup','destination'] as $key)$s[$key]=coarse_place($s[$key]);$s['stops']=array_map('coarse_place',$s['stops']);$s['route']=[];unset($s['note'],$s['location_retained_until_purge']);$s['location_purged_at']=gmdate('c');
 if(!$apply){$summary['trip_locations']++;continue;}
 $summary['trip_locations']+=transaction(function()use($t,$s,$ids,$lockUsers,$policy){
  if(!$lockUsers($ids))return ['count'=>0];$live=trip_row($t['id'],true);if((int)$live['version']!==(int)$t['version']||row('SELECT id FROM rs_cases WHERE trip_id=? AND status<>"resolved"',[$t['id']]))return ['count'=>0];
  sql('UPDATE rs_trips SET snapshot=?,pin_encrypted="",version=version+1 WHERE id=?',[j($s),$t['id']]);sql('UPDATE rs_quotes SET pickup=?,destination=?,stops=?,route_json="[]" WHERE id=?',[j($s['pickup']),j($s['destination']),j($s['stops']),$t['quote_id']]);sql('UPDATE rs_trip_changes SET before_json="{}",after_json="{}" WHERE trip_id=?',[$t['id']]);sql('UPDATE rs_events SET details="{}" WHERE trip_id=?',[$t['id']]);sql('DELETE FROM rs_messages WHERE trip_id=?',[$t['id']]);audit((int)$policy['owner_id'],'retention.trip.location',$t['id'],'Approved precise location and conversation expiry; fare/ledger retained');return ['count'=>1];
 })['count'];
}
foreach(rows('SELECT * FROM rs_cases WHERE status="resolved" AND subject<>"Removed under approved retention policy" AND updated_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? DAY) LIMIT 100',[$policy['closed_case_days']]) as $c){
 $t=$c['trip_id']?trip_row($c['trip_id']):null;$ids=[(int)$c['user_id'],(int)($t['customer_id']??0),(int)($t['driver_id']??0)];if(array_filter(array_filter($ids),$held))continue;
 if(!$apply){$summary['closed_case_messages']++;$summary['private_files']+=(int)sql('SELECT COUNT(*) FROM rs_attachments WHERE case_id=? AND scan_status<>"purged"',[$c['id']])->fetchColumn();continue;}
 $result=transaction(function()use($c,$ids,$lockUsers,$policy){
  if(!$lockUsers($ids))return ['cases'=>0,'files'=>0];$live=row('SELECT * FROM rs_cases WHERE id=? FOR UPDATE',[$c['id']]);if(!$live||$live['status']!=='resolved'||(int)$live['version']!==(int)$c['version'])return ['cases'=>0,'files'=>0];
  $files=rows('SELECT * FROM rs_attachments WHERE case_id=? AND scan_status<>"purged" FOR UPDATE',[$c['id']]);foreach($files as $file)purge_file('rs_attachments',$file);
  sql('UPDATE rs_case_messages SET body="Removed under approved retention policy" WHERE case_id=?',[$c['id']]);sql('UPDATE rs_cases SET subject="Removed under approved retention policy",version=version+1,updated_at=UTC_TIMESTAMP() WHERE id=?',[$c['id']]);audit((int)$policy['owner_id'],'retention.case',$c['id'],'Approved closed-case conversation and file expiry');return ['cases'=>1,'files'=>count($files)];
 });$summary['closed_case_messages']+=$result['cases'];$summary['private_files']+=$result['files'];
}
foreach(rows('SELECT d.* FROM rs_documents d JOIN rs_users u ON u.id=d.user_id WHERE u.status="deleted" AND d.created_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? DAY) AND scan_status<>"purged" LIMIT 100',[$policy['deleted_document_days']]) as $file){
 if($held((int)$file['user_id']))continue;if(!$apply){$summary['private_files']++;continue;}
 $summary['private_files']+=transaction(function()use($file,$lockUsers,$policy){
  if(!$lockUsers([(int)$file['user_id']])||row('SELECT status FROM rs_users WHERE id=?',[$file['user_id']])['status']!=='deleted')return ['count'=>0];$live=row('SELECT * FROM rs_documents WHERE id=? FOR UPDATE',[$file['id']]);if(!$live||$live['scan_status']==='purged')return ['count'=>0];purge_file('rs_documents',$live);audit((int)$policy['owner_id'],'retention.document',(string)$file['id'],'Approved deleted-account evidence expiry');return ['count'=>1];
 })['count'];
}
foreach(rows('SELECT user_id,heartbeat_at FROM rs_drivers WHERE desired_online=0 AND heartbeat_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? DAY) AND location_json IS NOT NULL',[$policy['trip_location_days']]) as $d){
 if($held((int)$d['user_id'])||row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$d['user_id']]))continue;if(!$apply){$summary['driver_locations']++;continue;}
 $summary['driver_locations']+=transaction(function()use($d,$lockUsers){if(!$lockUsers([(int)$d['user_id']]))return ['count'=>0];$live=row('SELECT * FROM rs_drivers WHERE user_id=? FOR UPDATE',[$d['user_id']]);if($live['desired_online']||$live['heartbeat_at']!==$d['heartbeat_at']||row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$d['user_id']]))return ['count'=>0];sql('UPDATE rs_drivers SET location_json=NULL WHERE user_id=?',[$d['user_id']]);return ['count'=>1];})['count'];
}
$summary['expired_sessions']=(int)sql('SELECT COUNT(*) FROM rs_sessions WHERE expires_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? DAY)',[$policy['session_days']])->fetchColumn();
if($apply){
 // Queue survives a crash between committed logical removal and filesystem deletion.
 foreach(rows('SELECT storage_key FROM rs_file_purges WHERE removed_at IS NULL LIMIT 500') as $q){$path=private_file_path($q['storage_key']);sql('UPDATE rs_file_purges SET attempts=attempts+1 WHERE storage_key=?',[$q['storage_key']]);if(!is_file($path)||@unlink($path)){sql('UPDATE rs_file_purges SET removed_at=UTC_TIMESTAMP() WHERE storage_key=?',[$q['storage_key']]);$summary['files_removed']++;}}
 sql('UPDATE rs_request_results SET result_json="{\"expired\":true}" WHERE JSON_UNQUOTE(JSON_EXTRACT(result_json,"$.expires_at"))<UTC_TIMESTAMP()');sql('DELETE FROM rs_sessions WHERE expires_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL ? DAY)',[$policy['session_days']]);audit((int)$policy['owner_id'],'retention.run',$policy['approved_request'],'Approved retention applied; financial records and legal holds preserved',null,$summary);
}
echo j($summary).PHP_EOL;
function coarse_place(array $p):array{$p['name']='Dhaka area';$p['address']='Removed under retention policy';$p['lat']=round((float)$p['lat'],2);$p['lng']=round((float)$p['lng'],2);return $p;}
function private_file_path(string $key):string{if(!preg_match('/^[a-f0-9]{32}$/',$key))throw new RuntimeException('Invalid private storage key.');$root=realpath(private_storage().'/documents');if(!$root)throw new RuntimeException('Private storage root missing.');$path=$root.DIRECTORY_SEPARATOR.$key;$resolved=realpath($path);if($resolved&&!str_starts_with($resolved,$root.DIRECTORY_SEPARATOR))throw new RuntimeException('Private file path escapes storage.');return $path;}
function purge_file(string $table,array $file):void{if(!in_array($table,['rs_documents','rs_attachments'],true))throw new RuntimeException('Unknown private file table.');private_file_path($file['storage_key']);sql('INSERT IGNORE INTO rs_file_purges(storage_key) VALUES(?)',[$file['storage_key']]);sql('UPDATE '.$table.' SET scan_status="purged" WHERE id=?',[$file['id']]);}
