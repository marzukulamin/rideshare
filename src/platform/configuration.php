<?php
declare(strict_types=1);
function configuration_plan(array $u,array $r,array $p):bool {
 if($r['kind']==='configuration_rollback'){
  $prior=row('SELECT * FROM rs_config_versions WHERE id=? FOR UPDATE',[required($p,'change_id',32)])??fail(404,'Configuration reference not found.');if($prior['status']!=='applied')fail(409,'Only applied configuration can be restored.');$before=decode($prior['before_json']);$target=$prior['target_key'];
  $live=str_starts_with($target,'product:')?row('SELECT * FROM rs_products WHERE id=? FOR UPDATE',[$before['id']]):row('SELECT * FROM rs_settings WHERE setting_key=? FOR UPDATE',[$target]);version_guard($live,$p);if((int)$live['version']!==(int)$before['version']+1)fail(409,'A later change exists. Review an explicit new configuration rather than silently overwriting it.');
  if(row('SELECT id FROM rs_config_versions WHERE target_key=? AND status="scheduled" FOR UPDATE',[$target]))fail(409,'A pending change must be resolved first.');
  $restore=isset($before['value_json'])?decode($before['value_json']):$before;
  $payload=['restore'=>$restore];sql('INSERT INTO rs_config_versions(id,kind,target_key,payload,before_json,effective_at,actor_id,request_id) VALUES(?,"configuration_rollback",?,?,?,UTC_TIMESTAMP(),?,?)',[$r['id'],$target,j($payload),j($live),$u['id'],$r['id']]);return true;
 }

 if(!in_array($r['kind'],['pricing','product','matching_pause','market']))return false;
 $kind=$r['kind'];$target=in_array($kind,['pricing','product'])?'product:'.(int)($p['product_id']??0):($kind==='market'?'market':'operations');
 if(in_array($kind,['pricing','product'])){$before=row('SELECT * FROM rs_products WHERE id=? FOR UPDATE',[(int)($p['product_id']??0)])??fail(404,'Product not found.');version_guard($before,$p);if($kind==='pricing'&&((int)($p['rate_minor']??0)<1||(int)$p['rate_minor']>1000000||(int)($p['driver_share_bps']??10000)<0||(int)($p['driver_share_bps']??10000)>10000))fail(422,'Invalid rate or driver share.');}
 else{$before=row('SELECT * FROM rs_settings WHERE setting_key=? FOR UPDATE',[$target]);if(isset($p['version'])&&(int)$p['version']!==(int)$before['version'])fail(409,'Settings changed after review.');if($kind==='market'&&((float)($p['radius_km']??0)<1||(float)$p['radius_km']>100))fail(422,'Use a service radius from 1 to 100 km.');}
 $effective=gmdate('Y-m-d H:i:s');if(!empty($p['effective_at'])){try{$date=new DateTimeImmutable(required($p,'effective_at',40));}catch(Throwable $e){fail(422,'Use an ISO date/time with timezone offset.');}if(!preg_match('/(?:Z|[+-]\d{2}:\d{2})$/',$p['effective_at'])||$date->getTimestamp()<time()-60||$date->getTimestamp()>time()+366*86400)fail(422,'Choose a present or future effective time with explicit timezone.');$effective=$date->setTimezone(new DateTimeZone('UTC'))->format('Y-m-d H:i:s');}
 if(row('SELECT id FROM rs_config_versions WHERE target_key=? AND status="scheduled" FOR UPDATE',[$target]))fail(409,'This target already has a scheduled change. Resolve it before another proposal.');
 sql('INSERT INTO rs_config_versions(id,kind,target_key,payload,before_json,effective_at,actor_id,request_id) VALUES(?,?,?,?,?,?,?,?)',[$r['id'],$kind,$target,j($p),j($before),$effective,$u['id'],$r['id']]);
 return true;
}
function promote_configuration():void {
 foreach(rows('SELECT id FROM rs_config_versions WHERE status="scheduled" AND effective_at<=UTC_TIMESTAMP() ORDER BY effective_at,id LIMIT 10') as $item){$change=row('SELECT * FROM rs_config_versions WHERE id=? FOR UPDATE',[$item['id']]);if(!$change||$change['status']!=='scheduled')continue;$p=decode($change['payload']);$before=decode($change['before_json']);$kind=$change['kind'];
  if($kind==='configuration_rollback'){
   $live=str_starts_with($change['target_key'],'product:')?row('SELECT * FROM rs_products WHERE id=? FOR UPDATE',[$before['id']]):row('SELECT * FROM rs_settings WHERE setting_key=? FOR UPDATE',[$change['target_key']]);if((int)$live['version']!==(int)$before['version']){sql('UPDATE rs_config_versions SET status="conflict" WHERE id=?',[$change['id']]);continue;}
   $restore=$p['restore'];if(str_starts_with($change['target_key'],'product:'))sql('UPDATE rs_products SET active=?,rate_minor=?,driver_share_bps=?,version=version+1 WHERE id=?',[(bool)$restore['active'],$restore['rate_minor'],$restore['driver_share_bps'],$live['id']]);else sql('UPDATE rs_settings SET value_json=?,version=version+1,updated_at=UTC_TIMESTAMP() WHERE setting_key=?',[j($restore),$change['target_key']]);
  }
  elseif(in_array($kind,['pricing','product'])){$live=row('SELECT * FROM rs_products WHERE id=? FOR UPDATE',[$before['id']]);if((int)$live['version']!==(int)$before['version']){sql('UPDATE rs_config_versions SET status="conflict" WHERE id=?',[$change['id']]);continue;}if($kind==='pricing')sql('UPDATE rs_products SET rate_minor=?,driver_share_bps=?,version=version+1 WHERE id=?',[$p['rate_minor'],$p['driver_share_bps']??$live['driver_share_bps'],$live['id']]);else sql('UPDATE rs_products SET active=?,version=version+1 WHERE id=?',[(bool)($p['active']??false),$live['id']]);}
  else{$live=row('SELECT * FROM rs_settings WHERE setting_key=? FOR UPDATE',[$change['target_key']]);if((int)$live['version']!==(int)$before['version']){sql('UPDATE rs_config_versions SET status="conflict" WHERE id=?',[$change['id']]);continue;}$v=decode($live['value_json']);if($kind==='market')$v['radius_km']=(float)$p['radius_km'];else $v['matching_paused']=(bool)($p['paused']??false);sql('UPDATE rs_settings SET value_json=?,version=version+1,updated_at=UTC_TIMESTAMP() WHERE setting_key=?',[j($v),$change['target_key']]);}
  sql('UPDATE rs_config_versions SET status="applied",applied_at=UTC_TIMESTAMP() WHERE id=?',[$change['id']]);audit((int)$change['actor_id'],'configuration.applied',$change['id'],'Approved effective configuration',decode($change['before_json']),$p);
 }
}
