<?php
declare(strict_types=1);
putenv('APP_ENV=local');require __DIR__.'/../src/platform/core.php';
$root=dirname(__DIR__);$c=decode(file_get_contents($root.'/.local/backend/credentials.json'));$config=decode(file_get_contents($root.'/.local/backend/config.json'));
if($config['host']!=='127.0.0.1'||(int)$config['port']!==3317||$config['database']!=='rideshare_connected')throw new RuntimeException('Backup verification is restricted to the isolated local database.');
$dir=$root.'/.local/backups';if(!is_dir($dir))mkdir($dir,0700,true);$stamp=gmdate('Ymd-His').'-'.bin2hex(random_bytes(3));$ini=$dir.'/client-'.$stamp.'.ini';$backup=$dir.'/rideshare-'.$stamp.'.sql';$restore='rideshare_restore_audit_'.str_replace('-','_',$stamp);
file_put_contents($ini,"[client]\nuser=root\npassword=".$c['rootPassword']."\nhost=127.0.0.1\nport=3317\n");
$admin=new PDO('mysql:host=127.0.0.1;port=3317;charset=utf8mb4','root',$c['rootPassword'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
function backup_process(array $args,array $desc):void{$pipes=[];$p=proc_open($args,$desc,$pipes);if(isset($pipes[0]))fclose($pipes[0]);if(isset($pipes[1])){stream_get_contents($pipes[1]);fclose($pipes[1]);}$errors=stream_get_contents($pipes[2]);fclose($pipes[2]);if(proc_close($p)!==0)throw new RuntimeException('Backup/restore command failed; private diagnostic length '.strlen($errors));}
try{
 $before=['journals'=>(int)sql('SELECT COUNT(*) FROM rs_journals')->fetchColumn(),'trips'=>(int)sql('SELECT COUNT(*) FROM rs_trips')->fetchColumn(),'users'=>(int)sql('SELECT COUNT(*) FROM rs_users')->fetchColumn()];
 backup_process(['E:/xamp/mysql/bin/mysqldump.exe','--defaults-extra-file='.$ini,'--single-transaction','--skip-lock-tables','--hex-blob',$config['database']],[0=>['pipe','r'],1=>['file',$backup,'w'],2=>['pipe','w']]);
 if(!preg_match('/^rideshare_restore_audit_[0-9a-f_]+$/',$restore))throw new RuntimeException('Unsafe restore schema.');$admin->exec('CREATE DATABASE `'.$restore.'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
 backup_process(['E:/xamp/mysql/bin/mysql.exe','--defaults-extra-file='.$ini,$restore],[0=>['file',$backup,'r'],1=>['pipe','w'],2=>['pipe','w']]);$copy=new PDO('mysql:host=127.0.0.1;port=3317;dbname='.$restore.';charset=utf8mb4','root',$c['rootPassword'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
 foreach($before as $table=>$count)if((int)$copy->query('SELECT COUNT(*) FROM rs_'.$table)->fetchColumn()!==$count)throw new RuntimeException('Restore count differs: '.$table);
 $imbalanced=(int)$copy->query('SELECT COUNT(*) FROM (SELECT journal_id FROM rs_entries GROUP BY journal_id HAVING SUM(amount_minor)<>0) x')->fetchColumn();if($imbalanced)throw new RuntimeException('Restored journals do not balance.');
 $backupFileCount=0;$fileDir=$dir.'/private-files-'.$stamp;if(!mkdir($fileDir,0700))throw new RuntimeException('Private evidence backup directory failed.');
 foreach(glob(private_storage().'/documents/*') as $file)if(is_file($file)){if(!copy($file,$fileDir.'/'.basename($file)))throw new RuntimeException('Private evidence copy failed.');$backupFileCount++;}
 // Secret is kept separately from publicly distributable source/artifacts, together with encrypted evidence.
 if(!copy($root.'/.local/backend/app-secret',$dir.'/app-secret-'.$stamp))throw new RuntimeException('Private encryption-key backup failed.');
 $result=['time'=>gmdate('c'),'passed'=>5,'restore_counts'=>$before,'balanced'=>true,'encrypted_files_copied'=>$backupFileCount,'sql_sha256'=>hash_file('sha256',$backup),'backup'=>basename($backup),'scope'=>'Isolated local schema restored to a fresh temporary schema; original untouched'];file_put_contents($root.'/.local/backend/backup-restore-verification.json',j($result));echo "Verified isolated restore counts, balanced journals and private evidence/key backup.\n";
}finally{if(is_file($ini))unlink($ini);if(preg_match('/^rideshare_restore_audit_[0-9a-f_]+$/',$restore))$admin->exec('DROP DATABASE IF EXISTS `'.$restore.'`');}
