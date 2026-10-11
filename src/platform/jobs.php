<?php
declare(strict_types=1);
require_once __DIR__."/account_policy.php";
function job_notice(string $key,int $user,string $category,string $title,string $body,?string $target=null):bool{
 return transaction(function()use($key,$user,$category,$title,$body,$target){$created=(bool)sql('INSERT IGNORE INTO rs_job_events(event_key,created_at) VALUES(?,UTC_TIMESTAMP())',[$key])->rowCount();if($created)notify($user,$category,$title,$body,$target);return ["created"=>$created];})["created"];
}
function operations_tick():array{
 if((int)sql('SELECT GET_LOCK("rideshare_operations_tick",0)')->fetchColumn()!==1)return ['skipped'=>'already_running'];
 try{
  housekeeping();transaction(function(){promote_configuration();return [];});$expired=restriction_expiry();$notices=0;$day=gmdate('Y-m-d');$ops=config('operations');
  $warningDays=max(1,min(30,(int)($ops['document_warning_days']??7)));
  foreach(rows('SELECT id,user_id,kind,expires_at FROM rs_documents WHERE status="approved" AND expires_at IS NOT NULL AND expires_at<DATE_ADD(UTC_TIMESTAMP(),INTERVAL ? DAY) LIMIT 300',[$warningDays]) as $d)$notices+=job_notice('document:'.$d['id'].':'.$day,(int)$d['user_id'],'onboarding','Document expiry review',$d['kind'].' expires '.$d['expires_at'].' UTC. Submit replacement evidence before expiry; expired evidence prevents new work.');
  foreach(rows('SELECT id,owner_id,restricted FROM rs_cases WHERE status<>"resolved" AND due_at<UTC_TIMESTAMP() LIMIT 300') as $c){
   $recipients=$c['owner_id']?[(int)$c['owner_id']]:array_map('intval',array_column(rows('SELECT DISTINCT user_id FROM rs_roles WHERE role_key=? AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP())',[$c['restricted']?'safety':'supervisor']),'user_id'));
   foreach($recipients as $id)if(array_intersect(roles_for($id),$c['restricted']?['safety']:['support','supervisor','dispatch']))$notices+=job_notice('case:'.$c['id'].':'.$id.':'.$day,$id,$c['restricted']?'safety':'support','Review is overdue','Open your eligible queue to review the overdue case; do not assume assistance was resolved.',$c['id']);
  }
  foreach(rows('SELECT user_id FROM rs_drivers WHERE desired_online=1 LIMIT 300') as $d){$ready=driver_readiness((int)$d['user_id']);$remaining=max(0,(int)$ready['work_limit_seconds']-(int)$ready['work_seconds']);if($remaining<=(int)($ops['work_warning_seconds']??900))$notices+=job_notice('work:'.$d['user_id'].':'.$day,(int)$d['user_id'],'safety','Work-time limit approaching','Remaining platform time: '.(int)ceil($remaining/60).' minutes. New offers stop at the limit. Finish or safely interrupt your current trip, then go offline for the required rest.');}
  $route=curl_init('http://127.0.0.1:8989/info');curl_setopt_array($route,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>2,CURLOPT_CONNECTTIMEOUT=>1,CURLOPT_FOLLOWLOCATION=>false]);$body=curl_exec($route);$routing=curl_getinfo($route,CURLINFO_RESPONSE_CODE)===200&&is_array(json_decode($body?:'',true));curl_close($route);
  $scan=@stream_socket_client('tcp://127.0.0.1:3320',$errno,$error,1);$scanner=false;if($scan){stream_set_timeout($scan,2);fwrite($scan,"zPING\0");$scanner=str_contains((string)fread($scan,64),'PONG');fclose($scan);}
  $health=['mysql'=>true,'routing'=>$routing,'scanner'=>$scanner];
  foreach($health as $dependency=>$healthy)if(!$healthy)foreach(rows('SELECT DISTINCT user_id FROM rs_roles WHERE role_key="oncall" AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP())') as $staff)$notices+=job_notice('health:'.$dependency.':'.$staff['user_id'].':'.gmdate('Y-m-d-H'),(int)$staff['user_id'],'safety','Local dependency needs attention',$dependency.' did not pass its local check. Open Operations health and the incident runbook; do not infer successful routing or scanning.');
  $summary=['as_of'=>gmdate('c'),'health'=>$health,'restrictions_processed'=>$expired,'notifications_created'=>$notices,'overdue_cases'=>(int)sql('SELECT COUNT(*) FROM rs_cases WHERE status<>"resolved" AND due_at<UTC_TIMESTAMP()')->fetchColumn(),'stale_online_drivers'=>(int)sql('SELECT COUNT(*) FROM rs_drivers WHERE desired_online=1 AND (heartbeat_at IS NULL OR heartbeat_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL 60 SECOND))')->fetchColumn(),'source'=>'Own database and loopback GraphHopper/ClamAV checks'];
  sql('INSERT INTO rs_job_state(job_key,summary,ran_at) VALUES("operations",?,UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE summary=VALUES(summary),ran_at=VALUES(ran_at)',[j($summary)]);return $summary;
 }finally{sql('SELECT RELEASE_LOCK("rideshare_operations_tick")');}
}
