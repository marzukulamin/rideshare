<?php
require __DIR__.'/test_client.php';
$role=$argv[1]??'customer_walkthrough';$token=login_fixture($role);$boot=ok_api('bootstrap',null,$token);$active=$boot['active_trip']??null;
$trip=$active?ok_api('trip',null,$token,['id'=>$active['id']]):null;
file_put_contents(__DIR__.'/../.local/verification/native-'.$role.'-state.json',j(['bootstrap'=>$boot,'detail'=>$trip]));
echo "Private fixture state refreshed.\n";
