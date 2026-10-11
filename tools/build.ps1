param(
 [ValidateSet('web','android','all')][string]$Target='all',
 [string]$BackendUrl='http://127.0.0.1:8098/',
 [string]$JavaHome='E:\Java',
 [string]$Drive='R:'
)
$ErrorActionPreference='Stop'
$projectRoot=(Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
if($BackendUrl -notmatch '^https://|^http://127\.0\.0\.1:8098/$'){throw 'Use your owned HTTPS backend, or the explicit local debugging endpoint.'}
$aliasRoot=$Drive+'\'
if(Test-Path -LiteralPath $aliasRoot){
 $aliasLine=(& subst | Where-Object {$_ -like ($Drive+'\: => *')})
 if(!$aliasLine -or $aliasLine.Substring($aliasLine.IndexOf('=>')+2).Trim() -ne $projectRoot){throw 'The selected drive must be a subst alias for this project.'}
}else{& subst $Drive $projectRoot;if($LASTEXITCODE){throw 'Cannot create project drive alias.'}}
if(!(Test-Path -LiteralPath ($aliasRoot+'.tools\flutter\bin\flutter.bat'))){throw 'This drive alias does not contain the project Flutter SDK.'}
$flutterTool=$aliasRoot+'.tools\flutter\bin\flutter.bat'
$env:PUB_CACHE=$aliasRoot+'.tools\pub-cache';$env:GRADLE_USER_HOME=$aliasRoot+'.tools\gradle'
$env:ANDROID_HOME=$aliasRoot+'.tools\android-sdk';$env:ANDROID_SDK_ROOT=$env:ANDROID_HOME;$env:JAVA_HOME=$JavaHome
& ($aliasRoot+'.tools\flutter\bin\cache\dart-sdk\bin\dart.exe') --disable-dart-dev (Join-Path $PSScriptRoot 'check_dart_runtime.dart')
if($LASTEXITCODE){throw 'Dart runtime startup failed. Resolve the execution environment before building; Flutter retries will not fix it.'}
$sourceBefore=(& C:\Python313\python.exe (Join-Path $PSScriptRoot 'build_sources.py') | ConvertFrom-Json).sourceSha256
if(!$sourceBefore -or $LASTEXITCODE){throw 'Cannot fingerprint active build sources.'}
Push-Location ($aliasRoot+'mobile')
try{
 & $flutterTool analyze;if($LASTEXITCODE){throw 'Analyzer failed.'}
 & $flutterTool test;if($LASTEXITCODE){throw 'Tests failed.'}
 if($Target -in @('web','all')){& $flutterTool build web --release --base-href=/demo/ --no-web-resources-cdn --no-wasm-dry-run "--dart-define=BACKEND_URL=$BackendUrl";if($LASTEXITCODE){throw 'Web build failed.'}}
 if($Target -in @('android','all')){
  $keyFile=$aliasRoot+'.local\signing\rideshare-portfolio.jks';$secretFile=$aliasRoot+'.local\signing\password.txt'
  if(!(Test-Path -LiteralPath $keyFile)){throw 'A private release signing key must be provisioned.'}
  $env:RIDESHARE_KEYSTORE_PATH=$keyFile;$env:RIDESHARE_KEYSTORE_PASSWORD=(Get-Content -LiteralPath $secretFile -Raw).Trim()
  & $flutterTool build apk --release "--dart-define=BACKEND_URL=$BackendUrl";if($LASTEXITCODE){throw 'Android build failed.'}
 }
 $meta=Join-Path $projectRoot '.local\build-metadata.json'
 $records=if(Test-Path -LiteralPath $meta){Get-Content -LiteralPath $meta -Raw | ConvertFrom-Json -AsHashtable}else{@{}}
 $version=(Select-String '^version:' pubspec.yaml).Line.Split(' ')[1]
 $builtAt=(Get-Date).ToUniversalTime().ToString('o')
 $sourceAfter=(& C:\Python313\python.exe (Join-Path $PSScriptRoot 'build_sources.py') | ConvertFrom-Json).sourceSha256
 if($sourceBefore -ne $sourceAfter){throw 'Active sources changed during the build. Rebuild before staging.'}
 if($Target -in @('web','all')){$records.web=@{version=$version;builtAt=$builtAt;sha256=(Get-FileHash -LiteralPath 'build\web\main.dart.js' -Algorithm SHA256).Hash.ToLower();backend='same-origin'}}
 if($Target -in @('android','all')){$records.android=@{version=$version;builtAt=$builtAt;sha256=(Get-FileHash -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' -Algorithm SHA256).Hash.ToLower();backend=$BackendUrl}}
 if($Target -in @('web','all')){$records.web.sourceSha256=$sourceAfter}
 if($Target -in @('android','all')){$records.android.sourceSha256=$sourceAfter}
 $records | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $meta -Encoding UTF8
}finally{Remove-Item Env:RIDESHARE_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue;Pop-Location}
& C:\Python313\python.exe (Join-Path $PSScriptRoot 'stage_release.py');if($LASTEXITCODE){throw 'Artifact staging failed.'}
