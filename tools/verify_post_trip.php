<?php
declare(strict_types=1);require __DIR__.'/test_client.php';require_once __DIR__.'/../src/platform/trips.php';require_once __DIR__.'/../src/platform/routing.php';require_once __DIR__.'/../src/platform/configuration.php';require_once __DIR__.'/../src/platform/jobs.php';
try{
 $customer=login_fixture('customer');$other=login_fixture('customer_secondary');$support=login_fixture('support');
 $trip=decode(file_get_contents(__DIR__.'/../.local/verification/browser-test-trip.json'))['id'];$t=trip_row($trip);$driver=login_fixture($t['driver_id']===row('SELECT id FROM rs_users WHERE phone=?',[$accounts['driver']['phone']])['id']?'driver':'driver_secondary');
 if($t['status']!=='completed'||!str_starts_with(row('SELECT name FROM rs_users WHERE id=?',[$t['customer_id']])['name'],'Test'))throw new RuntimeException('Use the completed isolated browser fixture.');
 ok_api('tip',['trip_id'=>$trip,'amount_minor'=>1000],$customer);
 ok_api('tip-change',['trip_id'=>$trip,'amount_minor'=>500,'expected_amount_minor'=>1000],$customer);check(tip_total($trip)===500,'Pending tip corrections use append-only journal deltas');
 [$s]=call_api('tip-change',['trip_id'=>$trip,'amount_minor'=>400,'expected_amount_minor'=>1000],$customer);check($s===409,'Stale tip edits cannot overwrite a newer declaration');
 [$s]=call_api('tip-change',['trip_id'=>$trip,'amount_minor'=>400,'expected_amount_minor'=>500],$other);check($s===403,'Another customer cannot change the trip tip');
 ok_api('tip-change',['trip_id'=>$trip,'amount_minor'=>0,'expected_amount_minor'=>500],$customer);check(tip_total($trip)===0,'A pending cash declaration can be cancelled without erasing its history');
 [$s]=call_api('confirm-tip',['trip_id'=>$trip,'expected_amount_minor'=>500,'evidence'=>'Old fixture amount'],$driver);check($s===409,'Driver cannot confirm a cancelled or changed cash tip');
 ok_api('tip-change',['trip_id'=>$trip,'amount_minor'=>750,'expected_amount_minor'=>0],$customer);ok_api('confirm-tip',['trip_id'=>$trip,'expected_amount_minor'=>750,'evidence'=>'Isolated receipt fixture; no real funds'],$driver);
 [$s]=call_api('tip-change',['trip_id'=>$trip,'amount_minor'=>500,'expected_amount_minor'=>750],$customer);check($s===409,'Received tips require a support correction rather than customer editing');
 check((int)row('SELECT e.amount_minor FROM rs_entries e JOIN rs_journals j ON j.id=e.journal_id WHERE j.reference_key=? AND e.account_key="customer_tip_declared"',['tip:'.$trip])['amount_minor']===1000,'Original tip journal remains immutable');
 ok_api('rate-trip',['trip_id'=>$trip,'rating'=>5,'tags'=>['clean_vehicle'],'feedback'=>'Fixture ordinary feedback'],$customer);
 [$s]=call_api('rate-trip',['trip_id'=>$trip,'rating'=>4,'tags'=>['clean_vehicle']],$customer);check($s===409,'Feedback edits are version guarded');
 ok_api('rate-trip',['trip_id'=>$trip,'version'=>1,'rating'=>4,'tags'=>['smooth_trip'],'feedback'=>'Fixture correction'],$customer);
 $rated=ok_api('trip',null,$customer,['id'=>$trip])['trip'];check($rated['rating']['tags']===['smooth_trip']&&(int)$rated['rating']['version']===2,'Structured feedback and current edit version persist');
 [$s]=call_api('rate-trip',['trip_id'=>$trip,'rating'=>1,'tags'=>[]],$support);check($s===403,'Staff cannot rate a customer trip by using their operational permissions');
 $ended=$t['ended_at'];sql('UPDATE rs_trips SET ended_at="2020-01-01 00:00:00" WHERE id=?',[$trip]);try{[$s]=call_api('rate-trip',['trip_id'=>$trip,'version'=>2,'rating'=>3,'tags'=>[]],$customer);check($s===409,'The database feedback window is enforced independently of UI');}finally{sql('UPDATE rs_trips SET ended_at=? WHERE id=?',[$ended,$trip]);}
 $pdf="%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF";[$s]=call_api('document-upload',['kind'=>'profile_photo','data'=>base64_encode($pdf)],$driver);check($s===422,'Profile photos reject PDF documents before storage');
 $first=operations_tick();check($first['health']['routing']&&$first['health']['scanner'],'Operational health checks use functional local router and scanner probes');
 $key='fixture:'.identifier();check(job_notice($key,$t['customer_id'],'support','Fixture notice','No real operation')&&!job_notice($key,$t['customer_id'],'support','Fixture notice','No real operation'),'Worker notification claims are durable and deduplicate retries');
 check(isset(ok_api('staff-overview',null,login_fixture('oncall'))['operations_health']),'On-call can inspect current dependency health');check(!isset(ok_api('staff-overview',null,$support)['operations_health']),'Routine support does not inherit operational dependency health');
 check((int)sql('SELECT COUNT(*) FROM (SELECT j.id FROM rs_journals j JOIN rs_entries e ON e.journal_id=j.id GROUP BY j.id HAVING SUM(e.amount_minor)<>0) balances')->fetchColumn()===0,'Tip corrections and receipt confirmation keep every journal balanced');
 file_put_contents(__DIR__.'/../.local/backend/post-trip-verification.json',j(['passed'=>$checks,'time'=>gmdate('c'),'trip_id'=>$trip]));echo "Verified {$checks} post-trip and maintenance checks.\n";
}catch(Throwable $e){fwrite(STDERR,$e->getMessage()."\n");exit(1);}
