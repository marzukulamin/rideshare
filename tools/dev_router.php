<?php
$root=dirname(__DIR__);$path=parse_url($_SERVER['REQUEST_URI'],PHP_URL_PATH);
if($path==='/api.php'){require $root.'/src/platform/endpoint.php';return;}
if($path==='/shared.php'){require $root.'/src/platform/shared.php';return;}
if($path==='/'||$path==='/demo'){header('Location: /demo/');return;}
$isDemo=getenv('APP_ENV')==='local'&&str_starts_with($path,'/demo/')&&is_file($root.'/mobile/build/web/main.dart.js');
$public=realpath($isDemo?$root.'/mobile/build/web':$root.'/release/site');$relative=$isDemo?substr($path,5):$path;$file=realpath($public.rawurldecode($relative));if($file&&is_dir($file))$file=realpath($file.'/index.html');
if(!$file||!is_file($file)||!str_starts_with($file,$public.DIRECTORY_SEPARATOR)){http_response_code(404);echo 'Not found';return;}
$types=['html'=>'text/html','js'=>'application/javascript','json'=>'application/json','css'=>'text/css','wasm'=>'application/wasm','png'=>'image/png','ttf'=>'font/ttf','otf'=>'font/otf','mp4'=>'video/mp4','vtt'=>'text/vtt','apk'=>'application/vnd.android.package-archive'];header('Content-Type: '.($types[pathinfo($file,PATHINFO_EXTENSION)]??'application/octet-stream'));header('X-Content-Type-Options: nosniff');readfile($file);
