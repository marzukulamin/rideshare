<?php
declare(strict_types=1);
// Administrative migration is deliberately separate from the restricted runtime connection.
$local=is_file(__DIR__.'/../.local/backend/config.json')?json_decode(file_get_contents(__DIR__.'/../.local/backend/config.json'),true):['host'=>'127.0.0.1','port'=>3306,'database'=>'rideshare'];
$host=getenv('DB_HOST')?:$local['host'];$port=getenv('DB_PORT')?:$local['port'];$name=getenv('DB_NAME')?:$local['database'];
if(!getenv('MIGRATION_DB_USER')&&($host!=='127.0.0.1'||(int)$port!==3317||$name!=='rideshare_connected'))throw new RuntimeException('Provide an explicit migration account for this database.');
$privateCredentials=is_file(__DIR__.'/../.local/backend/credentials.json')?json_decode(file_get_contents(__DIR__.'/../.local/backend/credentials.json'),true):[];
$db=new PDO("mysql:host=$host;port=$port;dbname=$name;charset=utf8mb4",getenv('MIGRATION_DB_USER')?:'root',getenv('MIGRATION_DB_PASSWORD')?:$privateCredentials['rootPassword'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$db->exec(file_get_contents(__DIR__.'/../database/connected-upgrade.sql'));
$db->exec('ALTER TABLE rs_users MODIFY totp_secret VARCHAR(255) NULL');
foreach(['rs_users'=>['access_version'=>'INT NOT NULL DEFAULT 1'],'rs_ratings'=>['tags'=>'JSON NULL','version'=>'INT NOT NULL DEFAULT 1','updated_at'=>'DATETIME NULL'],'rs_vehicles'=>['version'=>'INT NOT NULL DEFAULT 1','make'=>'VARCHAR(80) NULL','model'=>'VARCHAR(80) NULL','color'=>'VARCHAR(80) NULL'],'rs_quotes'=>['duration_seconds'=>'INT NOT NULL DEFAULT 0'],'rs_documents'=>['scan_status'=>"VARCHAR(24) NOT NULL DEFAULT 'pending'"]] as $table=>$columns)foreach($columns as $column=>$definition){$s=$db->prepare('SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=? AND TABLE_NAME=? AND COLUMN_NAME=?');$s->execute([$name,$table,$column]);if(!(int)$s->fetchColumn())$db->exec("ALTER TABLE $table ADD COLUMN $column $definition");}
if(!getenv('APP_ENV')&&!getenv('MIGRATION_DB_USER'))putenv('APP_ENV=local');require_once __DIR__.'/../src/platform/core.php';foreach(rows('SELECT id,totp_secret FROM rs_users WHERE totp_secret IS NOT NULL') as $user)if(!str_starts_with($user['totp_secret'],'enc:'))sql('UPDATE rs_users SET totp_secret=? WHERE id=?',['enc:'.encrypt_value($user['totp_secret']),$user['id']]);
echo "Additive connected schema migration applied. Existing trips and journals preserved.\n";
