<?php
require __DIR__.'/test_client.php';
$base=__DIR__.'/../.local/backend/signup-race-'.identifier();$phone='+88017'.(string)random_int(10000000,99999999);$terms=row('SELECT id FROM rs_terms WHERE kind="service" AND effective_at<=UTC_TIMESTAMP() ORDER BY effective_at DESC,id DESC LIMIT 1');
$input=$base.'.json';$barrier=$base.'-go';file_put_contents($input,j(['name'=>'TestConcurrentSignup','phone'=>$phone,'password'=>bin2hex(random_bytes(16)),'accept_terms'=>true,'terms_id'=>(int)$terms['id']]));$jobs=[];
try{
 for($i=0;$i<2;$i++){$out=$base.'-'.$i.'.json';$pipes=[];$p=proc_open([PHP_BINARY,__DIR__.'/signup_race_worker.php',$input,$out,$barrier],[0=>['pipe','r'],1=>['pipe','w'],2=>['pipe','w']],$pipes);$jobs[]=[$p,$pipes,$out];}
 file_put_contents($barrier,'go');$results=[];foreach($jobs as [$p,$pipes,$out]){foreach($pipes as $pipe)fclose($pipe);proc_close($p);$results[]=decode(file_get_contents($out));}
 check($results[0]['status']===200&&$results[1]['status']===200&&$results[0]['result']===$results[1]['result'],'Two concurrent duplicate signups return the same non-enumerating result');
 $users=rows('SELECT id FROM rs_users WHERE phone=?',[$phone]);check(count($users)===1,'Concurrent duplicate signup creates only one canonical account');$id=$users[0]['id'];
 check(count(rows('SELECT role_key FROM rs_roles WHERE user_id=?',[$id]))===1&&count(rows('SELECT terms_id FROM rs_consents WHERE user_id=?',[$id]))===1,'The unique account has exactly one customer grant and terms record');
 file_put_contents(__DIR__.'/../.local/backend/signup-race-verification.json',j(['passed'=>$checks,'time'=>gmdate('c'),'processes'=>2]));echo 'Verified '.$checks." concurrent signup checks.\n";
}finally{foreach([$input,$barrier,...array_column($jobs,2)] as $file)if(is_file($file))unlink($file);}
