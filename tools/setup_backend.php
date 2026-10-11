<?php
declare(strict_types=1);
$root=dirname(__DIR__);$private=$root.'/.local/backend';
$credentials=json_decode(file_get_contents($private.'/credentials.json'),true);
$pdo=new PDO('mysql:host=127.0.0.1;port=3317;charset=utf8mb4','root',$credentials['rootPassword'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$pdo->exec('CREATE DATABASE IF NOT EXISTS rideshare_connected CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
$password=$pdo->quote($credentials['appPassword']);
$pdo->exec("CREATE USER IF NOT EXISTS 'rideshare_app'@'127.0.0.1' IDENTIFIED BY {$password}");
$pdo->exec("GRANT SELECT,INSERT,UPDATE,DELETE ON rideshare_connected.* TO 'rideshare_app'@'127.0.0.1'");
$pdo->exec('USE rideshare_connected');
$pdo->exec(file_get_contents($root.'/database/platform.sql'));
file_put_contents($private.'/config.json',json_encode(['host'=>'127.0.0.1','port'=>3317,'database'=>'rideshare_connected','user'=>'rideshare_app','password'=>$credentials['appPassword']]));
if(!is_file($private.'/app-secret'))file_put_contents($private.'/app-secret',bin2hex(random_bytes(32)));
putenv('APP_ENV=local');require $root.'/src/platform/core.php';
sql('UPDATE rs_terms SET effective_at=UTC_TIMESTAMP() WHERE version="development-1" AND effective_at>UTC_TIMESTAMP()');
$settings=[
 'emergency'=>['number'=>'999','label'=>'Bangladesh national emergency services','source'=>'https://telecom-police.portal.gov.bd/pages/static-pages/695e3b0cc4774958d7b72321','verified_on'=>'2026-10-11','handoff'=>'Device dialer only; no automated emergency dispatch'],
 'market'=>['city'=>'Dhaka','currency'=>'BDT','timezone'=>'Asia/Dhaka','environment'=>'local','real_operations'=>false,'center_lat'=>23.7806,'center_lng'=>90.4070,'radius_km'=>38],
 'operations'=>['heartbeat_seconds'=>60,'offer_seconds'=>90,'work_limit_seconds'=>28800,'rest_seconds'=>28800,'matching_paused'=>false,'support_due_hours'=>24,'safety_due_minutes'=>15,'cancel_fee_minor'=>0,'max_stops'=>2,'max_tip_minor'=>100000,'policy_label'=>'Development operating rules; real-operation policy approval required'],
 'capabilities'=>['cash'=>true,'trip_pin'=>true,'trip_messages'=>true,'trip_sharing'=>true,'manual_settlement'=>true,'scheduling'=>false,'guest_booking'=>false,'parcel'=>false,'external_payments'=>false,'native_background_verified'=>false]
];
foreach($settings as $key=>$value)sql('INSERT IGNORE INTO rs_settings(setting_key,value_json) VALUES(?,?)',[$key,j($value)]);
file_put_contents($root.'/mobile/assets/emergency.json',j(config('emergency')));
if(!row('SELECT id FROM rs_terms LIMIT 1'))sql('INSERT INTO rs_terms(kind,version,title,body) VALUES(?,?,?,?)',['service','development-1','RideShare service terms','Development service: local database-backed test accounts and trips. No real vehicle dispatch or electronic payments. Accepted fares are locked upfront; cancellation before start has no fee. Cash collection requires an explicit record. Share links expire after two hours and can be revoked. Driver operation controls are restricted to the assigned driver. Real operation requires separately approved market policy.']);
if(!row('SELECT id FROM rs_products LIMIT 1'))foreach([['bike','Bike','One passenger, confirmed helmet equipment',1,['helmets'=>true]],['car','Car','Comfortable everyday rides',4,['luggage'=>true]],['cng','CNG','City rides by three-wheeler',3,['luggage'=>true]],['xl','XL','More seats for your party',6,['luggage'=>true]]] as [$key,$name,$desc,$capacity,$equipment])sql('INSERT INTO rs_products(product_key,name,description,capacity,requirements) VALUES(?,?,?,?,?)',[$key,$name,$desc,$capacity,j($equipment)]);
if(!row('SELECT id FROM rs_places LIMIT 1'))foreach([['Farmgate','Farmgate, Dhaka',23.7581,90.3897],['Dhanmondi Lake','Dhanmondi, Dhaka',23.7471,90.3745],['Bashundhara City','Panthapath, Dhaka',23.7508,90.3906],['Gulshan Lake Park','Gulshan 2, Dhaka',23.7943,90.4137],['National Museum','Shahbag, Dhaka',23.7384,90.3945],['Banani','Banani, Dhaka',23.7936,90.4066],['Airport','Airport Road, Dhaka',23.8433,90.3978]] as $place)sql('INSERT INTO rs_places(name,address,lat,lng) VALUES(?,?,?,?)',$place);
$accountsPath=$private.'/test-accounts.json';$accounts=is_file($accountsPath)?decode(file_get_contents($accountsPath)):[];
$types=['customer','driver','support','safety','dispatch','onboarding','finance','supervisor','admin','compliance','oncall','admin_reviewer','finance_reviewer','customer_secondary','driver_secondary','compliance_reviewer','oncall_reviewer','onboarding_reviewer'];
foreach($types as $index=>$type){
 $role=str_replace(['_reviewer','_secondary'],'',$type);
 $phone='+88017000000'.str_pad((string)($index+1),2,'0',STR_PAD_LEFT);
 $u=row('SELECT id FROM rs_users WHERE phone=?',[$phone]);
 if(!$u){$pass=ucfirst($type).'!'.bin2hex(random_bytes(6));$totp=in_array($role,['customer','driver'])?null:'JBSWY3DPEHPK3PXP'.substr(strtr(strtoupper(bin2hex(random_bytes(8))),'0189','ABCD'),0,8);
  sql('INSERT INTO rs_users(name,phone,password_hash,contact_status,preferences,totp_secret) VALUES(?,?,?,?,?,?)',['Test '.ucfirst($type),$phone,password_hash($pass,PASSWORD_DEFAULT),'manual_fixture',j(['pin_enabled'=>true,'simple_mode'=>false,'theme'=>'dark','notifications'=>true]),$totp]);$id=(int)connection()->lastInsertId();
  sql('INSERT INTO rs_roles(user_id,role_key) VALUES(?,?)',[$id,$role]);sql('INSERT INTO rs_consents(user_id,terms_id) SELECT ?,id FROM rs_terms',[$id]);
  $accounts[$type]=['phone'=>$phone,'password'=>$pass,'totpSecret'=>$totp];
  if($role==='driver'){
   sql('INSERT INTO rs_drivers(user_id,status,identity_status) VALUES(?,"approved","approved")',[$id]);
   foreach(rows('SELECT * FROM rs_products') as $p){sql('INSERT INTO rs_vehicles(driver_id,product_id,label,plate,capacity,equipment,status) VALUES(?,?,?,?,?,?,"approved")',[$id,$p['id'],'Test '.$p['name'].' vehicle','TEST-'.$type.'-'.$p['product_key'].'-001',$p['capacity'],$p['requirements']]);$v=connection()->lastInsertId();foreach(['license','registration','insurance'] as $kind)sql('INSERT INTO rs_documents(user_id,vehicle_id,kind,storage_key,mime,checksum,status,expires_at,reason) VALUES(?,?,?,?,?,?,"approved",DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 YEAR),?)',[$id,$v,$kind,'fixture-'.$kind,'application/x-test-fixture',hash('sha256','local-'.$v.$kind),'Isolated development fixture, not genuine verification']);if($p['product_key']==='car')sql('UPDATE rs_drivers SET active_vehicle_id=? WHERE user_id=?',[$v,$id]);}
  }
 }
}
file_put_contents($accountsPath,j($accounts));
echo "Connected schema installed. Private test accounts: .local/backend/test-accounts.json\n";
