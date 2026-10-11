<?php
declare(strict_types=1);
function case_access(array $u,array $case):void {
 if((int)$case['user_id']===$u['id'])return;
 if($case['restricted'])permit($u,'safety');
 elseif($case['category']==='assistance'){if(!permitted($u,'assistance')&&!permitted($u,'cases'))fail(403,'Assistance access is restricted.');}
 else permit($u,'cases');
 if($case['owner_id']&&$case['owner_id']!=$u['id']&&!permitted($u,'supervisor')&&!permitted($u,'safety'))fail(403,'This case belongs to another agent.');
}
function case_view(array $u,array $case,bool $markRead=false):array {
 case_access($u,$case);$case['attachments']=rows('SELECT id,mime,scan_status,created_at FROM rs_attachments WHERE case_id=? ORDER BY created_at',[$case['id']]);$case['messages']=rows('SELECT m.id,m.actor_id,m.body,m.internal_note,m.created_at,u.name FROM rs_case_messages m JOIN rs_users u ON u.id=m.actor_id WHERE m.case_id=? AND (?=0 OR m.internal_note=0) ORDER BY m.id',[$case['id'],(int)$case['user_id']===$u['id']?1:0]);
 if($markRead&&$case['messages'])sql('INSERT INTO rs_case_reads(case_id,reader_id,seen_message_id,seen_at) VALUES(?,?,?,UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE seen_message_id=GREATEST(seen_message_id,VALUES(seen_message_id)),seen_at=VALUES(seen_at)',[$case['id'],$u['id'],max(array_column($case['messages'],'id'))]);
 $reader=(int)$case['user_id']===$u['id']?(int)$case['owner_id']:(int)$case['user_id'];$seen=(int)(row('SELECT seen_message_id FROM rs_case_reads WHERE case_id=? AND reader_id=?',[$case['id'],$reader])['seen_message_id']??0);
 foreach($case['messages'] as &$message)if((int)$message['actor_id']===$u['id']&&!$message['internal_note'])$message['delivery']=$seen>=(int)$message['id']?'read':'saved';unset($message);
 if((int)$case['user_id']!==$u['id']){$locale=row('SELECT locale FROM rs_users WHERE id=?',[$case['user_id']])['locale'];$case['templates']=rows('SELECT content_key,title,body,version FROM rs_content WHERE content_key LIKE "template.%" AND locale=? AND active=1 AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP())',[$locale]);audit($u['id'],'case.read',$case['id'],'Permitted case context');}return $case;
}
function support_action(string $action,array $b,array $u):?array {
 if($action==='create-case'){
  $category=required($b,'category',40);if(!in_array($category,['fare','cash_dispute','lost_item','vehicle','safety','assistance','account','appeal','map','other']))fail(422,'Choose a supported issue category.');
  $tripId=text_value($b['trip_id']??'',32);if($tripId)participant($u,trip_row($tripId,true));$subject=required($b,'subject',160);$message=required($b,'message',4000);$restricted=$category==='safety';$id=identifier();
  $due=gmdate('Y-m-d H:i:s',time()+($restricted?900:86400));sql('INSERT INTO rs_cases(id,user_id,trip_id,category,subject,priority,restricted,due_at) VALUES(?,?,?,?,?,?,?,?)',[$id,$u['id'],$tripId?:null,$category,$subject,$restricted?'urgent':'normal',$restricted,$due]);sql('INSERT INTO rs_case_messages(case_id,actor_id,body) VALUES(?,?,?)',[$id,$u['id'],$message]);
  if($category==='cash_dispute'&&$tripId)sql('UPDATE rs_trips SET payment_status="disputed",version=version+1 WHERE id=?',[$tripId]);
  foreach(rows('SELECT DISTINCT user_id FROM rs_roles WHERE role_key=?',[$restricted?'safety':'support']) as $agent)notify((int)$agent['user_id'],$restricted?'safety':'support','New '.$category.' case','Open the assigned queue to review.',$id);return ['ok'=>true,'case_id'=>$id];
 }
 if($action==='cases'){
  $staff=($_GET['scope']??'own')==='staff';
  if(!$staff)$list=rows('SELECT * FROM rs_cases WHERE user_id=? ORDER BY updated_at DESC LIMIT 100',[$u['id']]);
  else{if(!permitted($u,'cases')&&!permitted($u,'assistance'))fail(403,'Case access is restricted.');$list=rows('SELECT * FROM rs_cases WHERE (?=1 OR restricted=0) AND (?=1 OR owner_id IS NULL OR owner_id=?) ORDER BY FIELD(priority,"urgent","normal"),due_at LIMIT 100',[permitted($u,'safety')?1:0,(permitted($u,'supervisor')||permitted($u,'safety'))?1:0,$u['id']]);}
  if($staff&&!permitted($u,'cases'))$list=array_values(array_filter($list,fn($c)=>$c['category']==='assistance'));
  return ['cases'=>array_map(fn($c)=>case_view($u,$c),$list),'as_of'=>gmdate('c')];
 }
 if($action==='case')return ['case'=>case_view($u,row('SELECT * FROM rs_cases WHERE id=?',[required($_GET,'id',32)])??fail(404,'Case not found.'),true)];
 if($action==='case-close'){
  $case=row('SELECT * FROM rs_cases WHERE id=? FOR UPDATE',[required($b,'id',32)])??fail(404,'Case not found.');if((int)$case['user_id']!==$u['id'])fail(403,'Only the case owner can close or reopen their conversation.');version_guard($case,$b);if($case['restricted']||$case['category']==='assistance')fail(409,'Urgent assistance and safety cases remain under staff review.');$next=!empty($b['reopen'])?'open':'resolved';sql('UPDATE rs_cases SET status=?,updated_at=UTC_TIMESTAMP(),version=version+1 WHERE id=?',[$next,$case['id']]);audit($u['id'],'case.customer.'.$next,$case['id'],'Case owner changed their conversation state');return ['ok'=>true];
 }
 if($action==='case-message'){
  $case=row('SELECT * FROM rs_cases WHERE id=? FOR UPDATE',[required($b,'id',32)])??fail(404,'Case not found.');case_access($u,$case);version_guard($case,$b);$message=required($b,'message',4000);$internal=!empty($b['internal_note']);if($internal&&(int)$case['user_id']===$u['id'])fail(403,'Internal notes are staff-only.');
  if((int)$case['user_id']!==$u['id']&&(int)$case['owner_id']!==$u['id'])fail(409,'Only the assigned staff member can respond. Claim or request reassignment first.');
  if(!empty($b['template_key'])){if((int)$case['user_id']===$u['id'])fail(403,'Reply templates are staff-only.');$locale=row('SELECT locale FROM rs_users WHERE id=?',[$case['user_id']])['locale'];$template=row('SELECT * FROM rs_content WHERE content_key=? AND locale=? AND active=1 AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP())',[required($b,'template_key',80),$locale]);if(!$template||!str_starts_with($template['content_key'],'template.'))fail(409,'This approved reply template is unavailable.');if((int)($b['template_version']??0)!==(int)$template['version'])fail(409,'The template changed. Refresh and preview the reply again.');}
  sql('INSERT INTO rs_case_messages(case_id,actor_id,body,internal_note) VALUES(?,?,?,?)',[$case['id'],$u['id'],$message,$internal]);sql('UPDATE rs_cases SET version=version+1,updated_at=UTC_TIMESTAMP(),status=IF(status="resolved","open",status) WHERE id=?',[$case['id']]);
  if(!$internal&&(int)$case['user_id']!==$u['id'])notify((int)$case['user_id'],'support','Support replied',$case['subject'],$case['id']);audit($u['id'],'case.message',$case['id'],$internal?'Internal staff note':'Case conversation response',null,['template_key'=>$b['template_key']??null,'template_version'=>$b['template_version']??null,'audience'=>$internal?'assigned staff':'case owner and eligible assigned staff']);return ['ok'=>true];
 }
 if($action==='case-update'){
  $case=row('SELECT * FROM rs_cases WHERE id=? FOR UPDATE',[required($b,'id',32)])??fail(404,'Case not found.');case_access($u,$case);if((int)$case['user_id']===$u['id'])fail(403,'Only permitted staff can change case ownership or outcome.');version_guard($case,$b);$reason=required($b,'reason',500);$next=required($b,'status',24);
  if(!in_array($next,['claim','in_progress','waiting_for_customer','resolved','escalate','reassign']))fail(422,'Choose a valid case action.');
  $owner=$case['owner_id'];$status=$case['status'];$restricted=$case['restricted'];
  if($next==='claim'){if($owner&&$owner!=$u['id'])fail(409,'Another staff member owns this case.');$owner=$u['id'];$status='in_progress';}
  elseif($next==='reassign'){permit($u,'supervisor');$owner=(int)($b['owner_id']??0);$roles=roles_for($owner);if(!in_array($restricted?'safety':'support',$roles)&&!in_array('supervisor',$roles))fail(422,'Choose a role-eligible agent.');}
  elseif($next==='escalate'){$restricted=true;$status='open';$owner=null;}
  else{if((int)$owner!==$u['id']&&!permitted($u,'supervisor'))fail(409,'Claim this case first.');$status=$next;}
  sql('UPDATE rs_cases SET owner_id=?,status=?,restricted=?,priority=IF(?=1,"urgent",priority),version=version+1,updated_at=UTC_TIMESTAMP() WHERE id=?',[$owner,$status,$restricted,$restricted,$case['id']]);audit($u['id'],'case.'.$next,$case['id'],$reason,['owner'=>$case['owner_id'],'status'=>$case['status']],['owner'=>$owner,'status'=>$status]);notify((int)$case['user_id'],'support','Case updated',$case['subject'].': '.str_replace('_',' ',$status),$case['id']);return ['ok'=>true];
 }
 if($action==='pairing-exclusion'){
  permit($u,'exclusions');$case=row('SELECT * FROM rs_cases WHERE id=?',[required($b,'case_id',32)])??fail(404,'Case not found.');if(!$case['restricted']||!$case['trip_id'])fail(422,'Use a restricted trip-linked safety case.');$trip=trip_row($case['trip_id']);if(!$trip['driver_id'])fail(422,'No assigned driver exists for this trip.');$reason=required($b,'reason',240);
  if(!empty($b['revoke']))sql('UPDATE rs_exclusions SET revoked_at=UTC_TIMESTAMP() WHERE customer_id=? AND driver_id=?',[$trip['customer_id'],$trip['driver_id']]);else sql('INSERT INTO rs_exclusions(customer_id,driver_id,case_id,expires_at,reason,actor_id) VALUES(?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL 30 DAY),?,?) ON DUPLICATE KEY UPDATE case_id=VALUES(case_id),expires_at=VALUES(expires_at),reason=VALUES(reason),actor_id=VALUES(actor_id),revoked_at=NULL',[$trip['customer_id'],$trip['driver_id'],$case['id'],$reason,$u['id']]);audit($u['id'],'pairing.exclusion',$case['id'],$reason);return ['ok'=>true];
 }
 return null;
}
