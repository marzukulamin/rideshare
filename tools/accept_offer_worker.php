<?php
putenv('APP_ENV=local');require __DIR__.'/../src/platform/core.php';require __DIR__.'/../src/platform/trips.php';require __DIR__.'/../src/platform/support.php';
$job=decode(file_get_contents($argv[1]));$_SERVER['REQUEST_METHOD']='POST';$_SERVER['HTTP_AUTHORIZATION']='Bearer '.$job['token'];$_SERVER['HTTP_IDEMPOTENCY_KEY']=$job['key'];$deadline=microtime(true)+5;
while(!is_file($argv[3])&&microtime(true)<$deadline)usleep(1000);
try{$u=authenticate();$result=mutate($u,'offer',$job['body'],fn($actor)=>trip_action('offer',$job['body'],$actor));file_put_contents($argv[2],j(['status'=>200,'result'=>$result]));}catch(HttpFailure $e){file_put_contents($argv[2],j(['status'=>$e->status,'error'=>$e->getMessage()]));}catch(Throwable $e){file_put_contents($argv[2],j(['status'=>500,'error'=>get_class($e)]));}
