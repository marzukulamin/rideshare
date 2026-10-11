param([string]$Serial)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'start_local.ps1')
$adb=Join-Path $root '.tools/android-sdk/platform-tools/adb.exe'
$devices=& $adb devices
if($LASTEXITCODE){throw 'ADB cannot start. Use a normal PowerShell session or approved execution outside the restricted process sandbox.'}
$ready=@($devices | Where-Object {$_ -match '^\S+\s+device$'} | ForEach-Object {($_ -split '\s+')[0]})
if(!$Serial){
 if($ready.Count -ne 1){throw 'Connect and authorize one Android device, or pass -Serial for the intended device.'}
 $Serial=$ready[0]
}
if($Serial -notin $ready){throw 'The selected Android device is disconnected or has not authorized USB debugging.'}
$probe=Invoke-WebRequest 'http://127.0.0.1:8098/api.php?action=public-terms' -TimeoutSec 20
if($probe.StatusCode -ne 200){throw 'The local backend is not ready.'}
& $adb -s $Serial reverse tcp:8098 tcp:8098
if($LASTEXITCODE){throw 'Cannot restore the Android USB connection to the local backend.'}
Write-Output "Local app connection restored for $Serial. Keep USB connected; repeat after disconnecting or restarting the device."
