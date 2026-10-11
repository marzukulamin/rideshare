<?php
declare(strict_types=1);
require __DIR__.'/test_client.php';require_once __DIR__.'/../src/platform/trips.php';require_once __DIR__.'/../src/platform/cash.php';require_once __DIR__.'/../src/platform/governance.php';require_once __DIR__.'/../src/platform/operations.php';
// Isolated, 2010-dated case; the 3650-day fixture policy cannot age current data.
$previous=row('SELECT * FROM rs_settings WHERE setting_key="retention"');$process=null;$pipes=[];
function approve_race_request(string $id,string $token,bool $execute):array{$r=row('SELECT * FROM rs_requests WHERE id=?',[$id]);ok_api('request-decision',['id'=>$id,'version'=>$r['version'],'proposal_hash'=>$r['proposal_hash'],'decision'=>'approved','reason'=>'Independent local concurrency fixture review'],$token);$r=row('SELECT * FROM rs_requests WHERE id=?',[$id]);if($execute)ok_api('request-execute',['id'=>$id,'version'=>$r['version'],'proposal_hash'=>$r['proposal_hash'],'evidence'=>'Isolated test only; no actual legal-policy claim'],$token);return $r;}
try{
 $privacy=login_fixture('compliance');$reviewer=login_fixture('compliance_reviewer');$phone='+88019'.random_int(10000000,99999999);$password=bin2hex(random_bytes(12));
 sql('INSERT INTO rs_users(name,phone,password_hash,preferences) VALUES(?,?,?,"{}")',['Test retention concurrency',$phone,password_hash($password,PASSWORD_DEFAULT)]);$target=(int)connection()->lastInsertId();sql('INSERT INTO rs_roles(user_id,role_key) VALUES(?,"customer")',[$target]);
 $customer=ok_api('login',['phone'=>$phone,'password'=>$password,'client'=>'android','device'=>'Isolated retention race fixture'])['token'];
 $case=ok_api('create-case',['category'=>'account','subject'=>'Preserve concurrent fixture','message'=>'Private concurrent evidence'],$customer)['case_id'];$c=row('SELECT * FROM rs_cases WHERE id=?',[$case]);
 ok_api('case-attachment',['id'=>$case,'version'=>$c['version'],'data'=>'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg=='],$customer);$file=row('SELECT * FROM rs_attachments WHERE case_id=?',[$case]);
 sql('UPDATE rs_cases SET status="resolved",updated_at="2010-01-01 00:00:00" WHERE id=?',[$case]);
 $policy=ok_api('create-request',['kind'=>'retention_policy','reason'=>'Concurrent hold regression on aged isolated fixture','payload'=>['trip_location_days'=>3650,'closed_case_days'=>3650,'deleted_document_days'=>3650,'session_days'=>3650,'legal_basis'=>'Local concurrency test only','jurisdiction'=>'Fixture','version'=>$previous['version']??0]],$privacy)['request_id'];approve_race_request($policy,$reviewer,true);
 $hold=ok_api('create-request',['kind'=>'legal_hold','reason'=>'Concurrent fixture preservation','payload'=>['user_id'=>$target,'legal_reason'=>'Test concurrent evidence hold','legal_basis'=>'Fixture only','jurisdiction'=>'Fixture','expires_at'=>gmdate('Y-m-d',time()+86400*30)]],$privacy)['request_id'];$approved=approve_race_request($hold,$reviewer,false);
 $_SERVER['HTTP_AUTHORIZATION']='Bearer '.$reviewer;$_SERVER['REQUEST_METHOD']='GET';$actor=authenticate();$journals=(int)sql('SELECT COUNT(*) FROM rs_journals')->fetchColumn();
 connection()->beginTransaction();sql('SELECT id FROM rs_users WHERE id=? FOR UPDATE',[$target]);
 $process=proc_open([PHP_BINARY,'-r','putenv("APP_ENV=local"); $argv=["retention_worker.php","--apply"]; require '.var_export(__DIR__.'/retention_worker.php',true).';'],[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes);fclose($pipes[0]);
 $blocked=false;for($i=0;$i<100;$i++){foreach(rows('SELECT INFO FROM information_schema.PROCESSLIST WHERE ID<>CONNECTION_ID() AND DB=DATABASE()') as $p)if(preg_match('/^SELECT id FROM rs_users WHERE id=(?:\\?|'.$target.') FOR UPDATE$/i',trim((string)$p['INFO'])))$blocked=true;if($blocked)break;usleep(100000);}
 check($blocked,'Concurrent retention actually waits on the held account row in another MySQL connection');
 operations_action('request-execute',['id'=>$hold,'version'=>$approved['version'],'proposal_hash'=>$approved['proposal_hash'],'evidence'=>'Actual independently approved local fixture execution'],$actor);connection()->commit();
 $out=stream_get_contents($pipes[1]);$error=stream_get_contents($pipes[2]);fclose($pipes[1]);fclose($pipes[2]);$pipes=[];$exit=proc_close($process);$process=null;if($exit!==0)throw new RuntimeException('Retention worker failed: '.$error);$result=decode(trim($out));clearstatcache();
 check(row('SELECT status FROM rs_requests WHERE id=?',[$hold])['status']==='executed','Actual reviewed execution commits the legal hold before retention resumes');
 check(row('SELECT subject FROM rs_cases WHERE id=?',[$case])['subject']==='Preserve concurrent fixture'&&is_file(private_storage().'/documents/'.$file['storage_key']),'Retention rechecks the committed hold and preserves case content and encrypted file');
 check(!row('SELECT storage_key FROM rs_file_purges WHERE storage_key=?',[$file['storage_key']]),'Held evidence never enters the physical purge queue');
 check((int)sql('SELECT COUNT(*) FROM rs_journals')->fetchColumn()===$journals,'Concurrent hold and retention preserve all financial journals');
 file_put_contents(__DIR__.'/../.local/backend/retention-race-verification.json',j(['passed'=>$checks,'time'=>gmdate('c'),'processes'=>2,'observedBlockedQuery'=>true,'retention'=>$result]));echo 'Verified '.$checks." concurrent retention/hold checks.\n";
}finally{
 if(connection()->inTransaction())connection()->rollBack();if(is_resource($process)){foreach($pipes as $pipe)if(is_resource($pipe))fclose($pipe);proc_close($process);}
 if($previous)sql('UPDATE rs_settings SET value_json=?,version=? WHERE setting_key="retention"',[$previous['value_json'],$previous['version']]);else sql('DELETE FROM rs_settings WHERE setting_key="retention"');
}
