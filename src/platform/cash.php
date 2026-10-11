<?php
declare(strict_types=1);
function cash_execute(array $u,array $r,array $p,string $evidence):bool {
 if(!in_array($r['kind'],['cash_resolution','manual_collection','interrupted_fare']))return false;
 $trip=trip_row((string)$r['trip_id'],true);$fare=(int)$trip['fare_minor'];if((int)($p['trip_version']??0)!==(int)$trip['version'])fail(409,'Collection state changed after proposal. Review a fresh financial proposal.');
 if($r['kind']==='interrupted_fare'){
  if($trip['status']!=='interrupted'||$trip['payment_status']!=='under_review'||row('SELECT trip_id FROM rs_fare_reviews WHERE trip_id=?',[$trip['id']]))fail(409,'This interrupted fare is not awaiting a first final review.');
  $snapshot=decode($trip['snapshot']);$amount=(int)($p['amount_minor']??-1);$earning=(int)($p['earning_minor']??-1);$meters=(int)($p['billable_distance_m']??-1);
  if($amount<0||$amount>(int)$snapshot['fare_minor']||$meters<0||$meters>(int)$snapshot['distance_m']||$earning<0||$earning>(int)$snapshot['base_fare_minor'])fail(422,'Reviewed fare, distance and earning must stay within the accepted contract.');required($p,'review_evidence',500);
  sql('INSERT INTO rs_fare_reviews(trip_id,request_id,accepted_fare_minor,final_fare_minor,earning_minor,billable_distance_m,evidence,actor_id) VALUES(?,?,?,?,?,?,?,?)',[$trip['id'],$r['id'],$snapshot['fare_minor'],$amount,$earning,$meters,$evidence,$u['id']]);
  journal($u,'fare','fare:'.$trip['id'],$trip['id'],[['account'=>'customer_receivable','user'=>(int)$trip['customer_id'],'amount'=>$amount],['account'=>'fare_revenue','amount'=>-$amount]],$evidence);
  journal($u,'earning','earning:'.$trip['id'],$trip['id'],[['account'=>'driver_cost','amount'=>$earning],['account'=>'driver_payable','user'=>(int)$trip['driver_id'],'amount'=>-$earning]],$evidence);
  sql('UPDATE rs_trips SET fare_minor=?,earning_minor=?,payment_status=?,version=version+1 WHERE id=?',[$amount,$earning,$amount===0?'not_due':'uncollected',$trip['id']]);notify((int)$trip['customer_id'],'payment','Interrupted fare reviewed','Your trip receipt now shows the independently reviewed fare. Help remains available.',$trip['id']);notify((int)$trip['driver_id'],'payment','Interrupted earnings reviewed','Open your earnings for the recorded outcome.',$trip['id']);return true;
 }
 if($trip['status']!=='completed'&&!($trip['status']==='interrupted'&&row('SELECT trip_id FROM rs_fare_reviews WHERE trip_id=?',[$trip['id']])))fail(409,'Only a finalized trip has a collectible fare.');
 if($r['kind']==='cash_resolution'){
  if(!in_array($trip['payment_status'],['collection_reported','disputed']))fail(409,'This trip has no unresolved collection report.');
  $reported=(int)sql('SELECT COALESCE(SUM(e.amount_minor),0) FROM rs_journals j JOIN rs_entries e ON e.journal_id=j.id WHERE j.reference_key=? AND e.account_key="driver_cash_held"',['cash:'.$trip['id']])->fetchColumn();
  if($reported<=0||row('SELECT id FROM rs_journals WHERE reference_key=?',['cash-resolution:'.$trip['id']]))fail(409,'The reported collection was already resolved or is unavailable.');
  $decision=required($p,'decision',24);if(!in_array($decision,['confirmed','reversed']))fail(422,'Confirm or reverse the reviewed collection report.');
  if($decision==='reversed')journal($u,'cash_report_reversal','cash-resolution:'.$trip['id'],$trip['id'],[['account'=>'driver_cash_held','user'=>(int)$trip['driver_id'],'amount'=>-$reported],['account'=>'customer_receivable','user'=>(int)$trip['customer_id'],'amount'=>$reported]],$evidence);
  else{$offset=min($reported,(int)$trip['earning_minor']);journal($u,'cash_earning_offset','cash-offset:'.$trip['id'],$trip['id'],[['account'=>'driver_payable','user'=>(int)$trip['driver_id'],'amount'=>$offset],['account'=>'driver_cash_held','user'=>(int)$trip['driver_id'],'amount'=>-$offset]],$evidence);journal($u,'cash_review_confirmed','cash-resolution:'.$trip['id'],$trip['id'],[['account'=>'review_confirmation','amount'=>0],['account'=>'review_control','amount'=>0]],$evidence);}
  sql('UPDATE rs_trips SET payment_status=?,version=version+1 WHERE id=?',[$decision==='confirmed'?'collected':'uncollected',$trip['id']]);
 }else{
  if(!in_array($trip['payment_status'],['uncollected','partially_collected']))fail(409,'Resolve any disputed or unconfirmed report before a new manual settlement.');
  $remaining=(int)sql('SELECT COALESCE(SUM(e.amount_minor),0) FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE j.trip_id=? AND e.account_key="customer_receivable"',[$trip['id']])->fetchColumn();$amount=(int)($p['amount_minor']??0);
  if($amount<=0||$amount>$remaining)fail(422,'The settlement must be within the verified remaining fare.');
  journal($u,'manual_collection','collection:'.$r['id'],$trip['id'],[['account'=>'manual_cash_received','amount'=>$amount],['account'=>'customer_receivable','user'=>(int)$trip['customer_id'],'amount'=>-$amount]],$evidence);
  sql('UPDATE rs_trips SET payment_status=?,version=version+1 WHERE id=?',[$amount===$remaining?'collected':'partially_collected',$trip['id']]);
 }
 notify((int)$trip['customer_id'],'payment','Cash review completed','Open your trip for the confirmed collection or remaining fare. Help remains available.',$trip['id']);return true;
}
