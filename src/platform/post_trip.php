<?php
declare(strict_types=1);
function tip_total(string $trip):int{return (int)sql('SELECT COALESCE(SUM(e.amount_minor),0) FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE j.trip_id=? AND e.account_key="customer_tip_declared"',[$trip])->fetchColumn();}
function feedback_policy():array{return config('feedback')+['rating_window_seconds'=>2592000,'tags'=>['clean_vehicle','smooth_trip','clear_pickup','respectful','route_feedback','communication_feedback']];}
function post_trip_action(string $action,array $b,array $u):?array{
 if(!in_array($action,['tip','tip-change','confirm-tip','rate-trip']))return null;
 $t=trip_row(required($b,'trip_id',32),true);participant($u,$t);
 if($t['status']!=='completed')fail(409,'This action requires a completed trip.');
 if($action==='rate-trip'){
  $policy=feedback_policy();if(strtotime($t['ended_at'])+(int)$policy['rating_window_seconds']<time())fail(409,'The feedback window has ended. Trip Help remains available.');
  $rating=(int)($b['rating']??0);if($rating<1||$rating>5)fail(422,'Rate a completed trip from 1 to 5.');
  $tags=$b['tags']??[];if(!is_array($tags)||count($tags)>3||array_diff($tags,$policy['tags']))fail(422,'Choose up to three supported feedback tags.');
  $old=row('SELECT * FROM rs_ratings WHERE trip_id=? AND actor_id=? FOR UPDATE',[$t['id'],$u['id']]);
  if($old)version_guard($old,$b);
  sql('INSERT INTO rs_ratings(trip_id,actor_id,rating,feedback,tags,updated_at) VALUES(?,?,?,?,?,UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE rating=VALUES(rating),feedback=VALUES(feedback),tags=VALUES(tags),version=version+1,updated_at=UTC_TIMESTAMP()',[$t['id'],$u['id'],$rating,text_value($b['feedback']??'',1000),j(array_values(array_unique($tags)))]);
  audit($u['id'],'trip.feedback',$t['id'],'Own completed-trip ordinary feedback; serious reports use Safety');return ['ok'=>true];
 }
 if($action==='confirm-tip'){
  permit($u,'driver');if((int)$t['driver_id']!==$u['id'])fail(403,'Only the assigned driver confirms this tip.');
  if(row('SELECT id FROM rs_journals WHERE reference_key=?',['tip-confirmed:'.$t['id']]))fail(409,'This cash tip is already confirmed.');
  $amount=tip_total($t['id']);if($amount<1)fail(409,'There is no pending cash tip to confirm.');
  if((int)($b['expected_amount_minor']??-1)!==$amount)fail(409,'The customer changed the pending tip. Refresh and review the current amount.');
  journal($u,'cash_tip_confirmed','tip-confirmed:'.$t['id'],$t['id'],[['account'=>'driver_tip_pending','user'=>$u['id'],'amount'=>$amount],['account'=>'driver_tip_received','user'=>$u['id'],'amount'=>-$amount]],required($b,'evidence',500));
  notify((int)$t['customer_id'],'payment','Cash tip received','The driver confirmed the cash tip on your trip receipt.',$t['id']);return ['ok'=>true];
 }
 permit($u,'customer');if((int)$t['customer_id']!==$u['id'])fail(403,'Change only your own trip tip.');
 if(row('SELECT id FROM rs_journals WHERE reference_key=?',['tip-confirmed:'.$t['id']]))fail(409,'A received cash tip cannot be edited. Use Trip Help for a correction review.');
 $amount=$b['amount_minor']??null;if(!is_int($amount)||$amount<($action==='tip'?100:0)||$amount>(int)config('operations')['max_tip_minor'])fail(422,'Choose a valid cash tip amount.');
 $exists=(bool)row('SELECT id FROM rs_journals WHERE reference_key=?',['tip:'.$t['id']]);$current=tip_total($t['id']);
 if($action==='tip'&&$exists)fail(409,'A tip declaration exists. Review and edit the pending declaration.');
 if($action==='tip-change'&&(!$exists||(int)($b['expected_amount_minor']??-1)!==$current))fail(409,'The pending tip changed. Refresh before editing it.');
 $delta=$amount-$current;if(!$delta)return ['ok'=>true,'unchanged'=>true];
 $reference=$action==='tip'?'tip:'.$t['id']:'tip-change:'.$t['id'].':'.substr(hash('sha256',required($_SERVER,'HTTP_IDEMPOTENCY_KEY',80)),0,32);
 journal($u,$action==='tip'?'cash_tip':'cash_tip_change',$reference,$t['id'],[['account'=>'customer_tip_declared','user'=>$u['id'],'amount'=>$delta],['account'=>'driver_tip_pending','user'=>(int)$t['driver_id'],'amount'=>-$delta]],$action==='tip'?'Cash tip declared; awaiting actual receipt':'Customer corrected pending declaration; original journal preserved');
 notify((int)$t['driver_id'],'payment',$amount?'Pending cash tip updated':'Pending cash tip cancelled','Review the current declaration and confirm only cash actually received.',$t['id']);return ['ok'=>true,'amount_minor'=>$amount];
}
