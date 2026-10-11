<?php
declare(strict_types=1);
function settlement_state(int $id):array {
 $hold=row('SELECT held,reason,version,request_id FROM rs_settlement_controls WHERE user_id=?',[$id]);
 $pending=(int)sql('SELECT COUNT(*) FROM rs_requests WHERE user_id=? AND kind="payout_destination" AND status IN ("pending","approved") AND expires_at>UTC_TIMESTAMP()',[$id])->fetchColumn();
 return ['held'=>(bool)($hold['held']??false),'reason'=>$hold['reason']??null,'version'=>(int)($hold['version']??0),'pending_destination_review'=>$pending>0,'channel'=>'Reviewed manual settlement; notices are saved in this account inbox'];
}
function settlement_guard(int $id):void {
 sql('SELECT id FROM rs_users WHERE id=? FOR UPDATE',[$id]);$state=settlement_state($id);
 if($state['held'])fail(409,'Settlement is held for independent finance review. See the recorded reason in your account.');
 if($state['pending_destination_review'])fail(409,'A destination change is awaiting independent review. Complete or withdraw that review before settlement.');
}
function settlement_hold(array $u,array $r,array $p,string $evidence):void {
 $id=(int)($p['user_id']??0);sql('SELECT id FROM rs_users WHERE id=? FOR UPDATE',[$id]);$old=row('SELECT * FROM rs_settlement_controls WHERE user_id=? FOR UPDATE',[$id]);
 if((int)($p['version']??-1)!==(int)($old['version']??0))fail(409,'The settlement hold changed since review. Submit a fresh proposal.');
 if(!is_bool($p['held']??null)||!row('SELECT user_id FROM rs_drivers WHERE user_id=?',[$id]))fail(422,'Choose an existing driver and explicit hold or release.');
 sql('INSERT INTO rs_settlement_controls(user_id,held,reason,request_id) VALUES(?,?,?,?) ON DUPLICATE KEY UPDATE held=VALUES(held),reason=VALUES(reason),request_id=VALUES(request_id),version=version+1',[$id,$p['held'],$evidence,$r['id']]);
 notify($id,'security',$p['held']?'Manual settlement held':'Manual settlement hold released',$r['reason'].'. Pending destination verification and current eligibility still apply.',null);
}
