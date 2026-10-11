<?php
declare(strict_types=1);
date_default_timezone_set('UTC');

final class HttpFailure extends RuntimeException {
    public function __construct(public int $status, string $message) { parent::__construct($message); }
}
function fail(int $code, string $message): never { throw new HttpFailure($code,$message); }
function out(array $value,int $status=200): never {
    http_response_code($status); header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store'); header('X-Content-Type-Options: nosniff');
    echo json_encode($value,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES); exit;
}
function connection(): PDO {
    static $pdo;
    if ($pdo) return $pdo;
    if(getenv('APP_ENV')!=='local')foreach(['DB_HOST','DB_PORT','DB_NAME','DB_USER','DB_PASSWORD','APP_SECRET'] as $key)if(!getenv($key))fail(503,'Production server configuration is incomplete.');
    $cfg=[]; $path=__DIR__.'/../../.local/backend/config.json';
    if (getenv('APP_ENV')==='local' && is_file($path)) $cfg=json_decode(file_get_contents($path),true);
    $pdo=new PDO('mysql:host='.(getenv('DB_HOST')?:($cfg['host']??'127.0.0.1')).';port='.(getenv('DB_PORT')?:($cfg['port']??3317)).';dbname='.(getenv('DB_NAME')?:($cfg['database']??'rideshare_connected')).';charset=utf8mb4',getenv('DB_USER')?:($cfg['user']??'rideshare_app'),getenv('DB_PASSWORD')?:($cfg['password']??''),[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]);
    $pdo->exec("SET time_zone='+00:00'");$pdo->exec('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED');return $pdo;
}
function sql(string $query,array $args=[]): PDOStatement { $s=connection()->prepare($query);foreach(array_values($args) as $i=>$value)$s->bindValue($i+1,$value,is_bool($value)?PDO::PARAM_BOOL:(is_int($value)?PDO::PARAM_INT:($value===null?PDO::PARAM_NULL:PDO::PARAM_STR)));$s->execute();return $s; }
function row(string $query,array $args=[]): ?array { return sql($query,$args)->fetch()?:null; }
function rows(string $query,array $args=[]): array { return sql($query,$args)->fetchAll(); }
function text_value(mixed $value,int $limit=240): string {
    if (!is_scalar($value) && $value!==null) fail(422,'Invalid text value.');
    $s=trim((string)$value); if(mb_strlen($s)>$limit) fail(422,"Use at most {$limit} characters."); return $s;
}
function required(array $b,string $key,int $limit=240): string { $s=text_value($b[$key]??'',$limit); if($s==='')fail(422,'Complete the '.$key.' field.');return $s; }
function j(mixed $value): string { return json_encode($value,JSON_THROW_ON_ERROR|JSON_UNESCAPED_UNICODE); }
function decode(mixed $value): mixed { return is_string($value)?json_decode($value,true):$value; }
function identifier(): string { return bin2hex(random_bytes(16)); }
function roles_for(int $id): array { return array_column(rows('SELECT role_key FROM rs_roles WHERE user_id=? AND (expires_at IS NULL OR expires_at>UTC_TIMESTAMP())',[$id]),'role_key'); }
const PERMISSIONS=[
 'customer'=>['customer','own_account','own_cases'],
 'driver'=>['driver','own_account','own_cases'],
 'driver_applicant'=>['driver_application','own_account','own_cases'],
 'support'=>['cases','trips','own_account','own_cases'],
 'safety'=>['safety','cases','trips','exclusions','assistance','own_account','own_cases'],
 'dispatch'=>['dispatch','trips','assistance','own_account','own_cases'],
 'onboarding'=>['onboarding','own_account','own_cases'],
 'finance'=>['finance','reports','own_account','own_cases'],
 'supervisor'=>['supervisor','cases','trips','reports','own_account','own_cases'],
 'admin'=>['configuration','access','audit','reports','own_account','own_cases'],
 'compliance'=>['privacy','audit','reports','own_account','own_cases'],
 'oncall'=>['incidents','audit','own_account','own_cases']
];
function permissions_for(array $roles): array { $a=[];foreach($roles as $r)$a=array_merge($a,PERMISSIONS[$r]??[]);return array_values(array_unique($a)); }
function scoped_permissions(array $roles,string $status):array { $permissions=permissions_for($roles);return $status==='active'?$permissions:array_values(array_intersect($permissions,['customer','driver','driver_application','own_account','own_cases'])); }
function actor_permissions(int $id,array $roles,string $status):array {
 $permissions=scoped_permissions($roles,$status);
 if(row('SELECT trip_id FROM rs_active WHERE actor_type="driver" AND actor_id=?',[$id]))$permissions=array_values(array_unique([...$permissions,'active_driver','own_account','own_cases']));
 return $permissions;
}
function permit_current_driver(array $u):void {if(!permitted($u,'driver')&&!permitted($u,'active_driver'))fail(403,'Only a driver with granted work access or their existing assignment may use this action.');}
function permitted(array $u,string $permission): bool { return in_array($permission,$u['permissions'],true); }
function permit(array $u,string $permission): void { if(!permitted($u,$permission))fail(403,'This action is not available to your account.'); }
function audit(?int $actor,string $action,string $id,string $reason,mixed $before=null,mixed $after=null):void { sql('INSERT INTO rs_audit(actor_id,action_key,entity_id,reason,before_json,after_json) VALUES(?,?,?,?,?,?)',[$actor,$action,$id,$reason,$before===null?null:j($before),$after===null?null:j($after)]); }
function notify(int $user,string $category,string $title,string $body,?string $target=null):void { sql('INSERT INTO rs_notifications(user_id,category,title,body,target_id) VALUES(?,?,?,?,?)',[$user,$category,$title,$body,$target]); }
function event(array $trip,array $u,string $key,array $details=[]):void { sql('INSERT INTO rs_events(trip_id,actor_id,event_key,details,request_id) VALUES(?,?,?,?,?)',[$trip['id'],$u['id'],$key,j($details),$_SERVER['HTTP_IDEMPOTENCY_KEY']??null]); }
function limit_attempts(string $scope,int $max,int $minutes=15):void {
    $key=hash('sha256',$scope); sql('INSERT INTO rs_rate_limits(bucket,hits,reset_at) VALUES(?,1,DATE_ADD(UTC_TIMESTAMP(),INTERVAL ? MINUTE)) ON DUPLICATE KEY UPDATE hits=IF(reset_at<UTC_TIMESTAMP(),1,hits+1),reset_at=IF(reset_at<UTC_TIMESTAMP(),VALUES(reset_at),reset_at)',[$key,$minutes]);
    if((int)row('SELECT hits FROM rs_rate_limits WHERE bucket=?',[$key])['hits']>$max)fail(429,'Too many attempts. Please wait and try again.');
}
function config(string $key):array { return decode(row('SELECT value_json FROM rs_settings WHERE setting_key=?',[$key])['value_json']??'{}'); }
function encrypt_value(string $plain):string {
    $key=secret_key();$iv=random_bytes(12);$tag='';$cipher=openssl_encrypt($plain,'aes-256-gcm',$key,OPENSSL_RAW_DATA,$iv,$tag);return base64_encode($iv.$tag.$cipher);
}
function decrypt_value(string $cipher):string { $data=base64_decode($cipher,true);return (string)openssl_decrypt(substr($data,28),'aes-256-gcm',secret_key(),OPENSSL_RAW_DATA,substr($data,0,12),substr($data,12,16)); }
function secret_key():string { $s=getenv('APP_SECRET');if(!$s&&getenv('APP_ENV')==='local')$s=file_get_contents(__DIR__.'/../../.local/backend/app-secret');if(!$s)fail(503,'Server encryption is not configured.');return hash('sha256',$s,true); }
function base32_decode(string $s):string { $bits='';foreach(str_split(strtoupper($s)) as $c){$p=strpos('ABCDEFGHIJKLMNOPQRSTUVWXYZ234567',$c);if($p!==false)$bits.=str_pad(decbin($p),5,'0',STR_PAD_LEFT);} $out='';foreach(str_split($bits,8) as $b)if(strlen($b)===8)$out.=chr(bindec($b));return $out; }
function totp_code(string $secret,int $step):string { $bin=pack('N2',0,$step);$hash=hash_hmac('sha1',$bin,base32_decode($secret),true);$o=ord($hash[19])&15;$n=unpack('N',substr($hash,$o,4))[1]&0x7fffffff;return str_pad((string)($n%1000000),6,'0',STR_PAD_LEFT); }
function valid_totp(string $secret,string $code):bool { if(str_starts_with($secret,'enc:'))$secret=decrypt_value(substr($secret,4)); for($d=-1;$d<=1;$d++)if(hash_equals(totp_code($secret,(int)floor(time()/30)+$d),$code))return true;return false; }
function authenticate(bool $optional=false):?array {
    $header=$_SERVER['HTTP_AUTHORIZATION']??'';$bearer=str_starts_with($header,'Bearer ');$token=$bearer?substr($header,7):($_COOKIE['rs_session']??'');
    if(!$token){if($optional)return null;fail(401,'Sign in to continue.');}
    $session=row('SELECT s.*,u.name,u.phone,u.email,u.status,u.contact_status,u.locale,u.preferences FROM rs_sessions s JOIN rs_users u ON u.id=s.user_id WHERE s.token_hash=? AND s.revoked_at IS NULL AND s.expires_at>UTC_TIMESTAMP()',[hash('sha256',$token)]);
    if(!$session){if($optional)return null;fail(401,'Your session expired. Sign in again.');}
    $u=['id'=>(int)$session['user_id'],'name'=>$session['name'],'phone'=>$session['phone'],'email'=>$session['email'],'status'=>$session['status'],'contact_status'=>$session['contact_status'],'locale'=>$session['locale'],'preferences'=>decode($session['preferences']),'session_id'=>(int)$session['id'],'csrf'=>$session['csrf'],'roles'=>roles_for((int)$session['user_id'])];
    $u['permissions']=actor_permissions($u['id'],$u['roles'],$u['status']);$u['bearer']=$bearer;
    if($_SERVER['REQUEST_METHOD']==='POST' && !$bearer && !hash_equals($session['csrf'],$_SERVER['HTTP_X_CSRF_TOKEN']??''))fail(419,'Your security token expired. Refresh and try again.');
    if(array_diff($u['roles'],['customer','driver','driver_applicant']) && (!$session['mfa_at'] || strtotime($session['mfa_at'])<time()-3600))fail(401,'Staff authentication expired. Sign in with your authentication code.');
    sql('UPDATE rs_sessions SET seen_at=UTC_TIMESTAMP() WHERE id=?',[$session['id']]);return $u;
}
function marketplace_user(array $u):void { if($u['status']!=='active')fail(403,'Booking is restricted. Help and appeals remain available.'); }
function version_guard(array $record,array $b):void { if(!isset($b['version']) || (int)$b['version']!==(int)$record['version'])fail(409,'This record changed. Refresh and review the latest version before retrying.'); }
function transaction(callable $fn):array {
 $pdo=connection();
 for($attempt=0;;$attempt++){
  $pdo->beginTransaction();
  try{$v=$fn();$pdo->commit();return $v;}
  catch(Throwable $e){
   if($pdo->inTransaction())$pdo->rollBack();
   if($e instanceof PDOException&&in_array((int)($e->errorInfo[1]??0),[1205,1213],true)){
    if($attempt<2){usleep(random_int(20000,80000));continue;}
    fail(409,'A concurrent operation changed this record. Refresh to confirm the durable outcome before retrying.');
   }
   throw $e;
  }
 }
}
function mutate(array $u,string $action,array $body,callable $fn):array {
    $key=text_value($_SERVER['HTTP_IDEMPOTENCY_KEY']??'',80);if(strlen($key)<16)fail(422,'A request identity is required.');
    $hash=hash('sha256',j($body));return transaction(function()use($u,$action,$body,$fn,$key,$hash){
        sql('SELECT id FROM rs_users WHERE id=? FOR UPDATE',[$u['id']]);
        $session=row('SELECT revoked_at,expires_at FROM rs_sessions WHERE id=? FOR UPDATE',[$u['session_id']]);if(!$session||$session['revoked_at']||strtotime($session['expires_at'])<=time())fail(401,'Your session was revoked or expired.');
        $u['roles']=roles_for($u['id']);$u['status']=row('SELECT status FROM rs_users WHERE id=?',[$u['id']])['status'];$u['permissions']=actor_permissions($u['id'],$u['roles'],$u['status']);
        $old=row('SELECT * FROM rs_operations WHERE user_id=? AND operation_key=? FOR UPDATE',[$u['id'],$key]);
        if($old){if($old['action_key']!==$action||$old['body_hash']!==$hash)fail(409,'This request identity belongs to another operation.');return decode($old['response_json']);}
        $result=$fn($u);sql('INSERT INTO rs_operations(user_id,operation_key,action_key,body_hash,response_json) VALUES(?,?,?,?,?)',[$u['id'],$key,$action,$hash,j($result)]);return $result;
    });
}

function private_storage():string {return rtrim(getenv('RS_PRIVATE_DIR')?:__DIR__.'/../../.local', '/\\');}
