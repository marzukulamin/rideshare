$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$alias='R:'
$line=& subst | Where-Object {$_ -like 'R:\: => *'}
if($line){if($line.Substring($line.IndexOf('=>')+2).Trim() -ne $root){throw 'R: belongs to a different workspace.'}}else{& subst R: $root;if($LASTEXITCODE){throw 'Cannot create project alias.'}}
$env:APP_ENV='local'
function Ensure-Service([string]$name,[int]$port,[string]$exe,[string[]]$arguments,[string]$marker){
 $listener=Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
 if($listener){$owner=Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)";if(!$owner -or $owner.CommandLine -notmatch $marker){throw "$name port $port is occupied by an unrecognized service."};return @{name=$name;pid=$owner.ProcessId;port=$port;state='existing'}}
 $process=Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root ".local/backend/$name-output.log") -RedirectStandardError (Join-Path $root ".local/backend/$name-error.log") -PassThru
 return @{name=$name;pid=$process.Id;port=$port;state='started'}
}
$services=@()
$services+=Ensure-Service 'mysql' 3317 'E:\xamp\mysql\bin\mysqld.exe' @('--defaults-file="R:\.local\mysql\my.ini"','--bind-address=127.0.0.1','--port=3317','--console') '3317'
$services+=Ensure-Service 'routing' 8989 'E:\Java\bin\java.exe' @('-Xmx1800m','-jar','R:\.local\routing\graphhopper-web-11.1.jar','server','R:\tools\routing.yml') 'graphhopper-web-11\.1\.jar'
$services+=Ensure-Service 'scanner' 3320 'R:\.tools\clamav\clamav-1.5.4.win.x64\clamd.exe' @('--config-file=R:\.local\clamd.conf') 'clamd\.conf'
$services+=Ensure-Service 'php' 8098 'E:\xamp\php\php.exe' @('-S','127.0.0.1:8098','-t','public','tools/dev_router.php') 'dev_router\.php'
$record=Join-Path $root '.local/backend/operations-process.json'
$existing=if(Test-Path $record){Get-Content $record -Raw | ConvertFrom-Json}else{$null}
$worker=if($existing){Get-CimInstance Win32_Process -Filter "ProcessId=$($existing.pid)" -ErrorAction SilentlyContinue}else{$null}
if(!$worker -or $worker.CommandLine -notmatch 'tools[/\\]operations_worker\.php'){
 $process=Start-Process -FilePath E:\xamp\php\php.exe -ArgumentList 'tools/operations_worker.php','--watch' -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root '.local/backend/operations-output.log') -RedirectStandardError (Join-Path $root '.local/backend/operations-error.log') -PassThru
 @{pid=$process.Id;kind='RideShare operations';startedAt=(Get-Date).ToUniversalTime().ToString('o')} | ConvertTo-Json | Set-Content $record
 $services+=@{name='operations';pid=$process.Id;state='started'}
}else{$services+=@{name='operations';pid=$worker.ProcessId;state='existing'}}
$services | ConvertTo-Json -Depth 4
