<?php
declare(strict_types=1);
if(PHP_SAPI!=='cli')exit(1);
require __DIR__.'/../src/platform/core.php';
foreach(['trips','routing','configuration','jobs'] as $module)require_once __DIR__.'/../src/platform/'.$module.'.php';
$watch=in_array('--watch',$argv,true);
do{try{echo j(operations_tick()).PHP_EOL;}catch(Throwable $e){fwrite(STDERR,'Operations tick failed: '.get_class($e).PHP_EOL);if(!$watch)exit(1);}if($watch)sleep(30);}while($watch);
