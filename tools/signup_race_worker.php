<?php
putenv('APP_ENV=local');require __DIR__.'/../src/platform/core.php';require __DIR__.'/../src/platform/identity.php';
$input=decode(file_get_contents($argv[1]));$deadline=microtime(true)+10;while(!is_file($argv[3])&&microtime(true)<$deadline)usleep(10000);
try{$r=identity_action('signup',$input,null);file_put_contents($argv[2],j(['status'=>200,'result'=>$r]));}catch(Throwable $e){file_put_contents($argv[2],j(['status'=>500,'error'=>'Concurrent fixture signup failed']));exit(1);}
