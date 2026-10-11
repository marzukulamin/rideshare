<?php
require __DIR__.'/test_client.php';$token=login_fixture('customer_walkthrough');$b=ok_api('bootstrap',null,$token);$t=$b['active_trip']??null;
if($t){if($t['status']==='in_progress')throw new RuntimeException('Do not cancel an in-progress fixture');ok_api('cancel-trip',['trip_id'=>$t['id'],'version'=>$t['version'],'reason'=>'Recover failed isolated native verification'],$token);}
echo "Native fixture ready for a new verification.\n";
