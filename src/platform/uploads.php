<?php
declare(strict_types=1);
function scan_bytes(string $bytes):string {
 $scan='pending';$socket=@stream_socket_client('tcp://127.0.0.1:3320',$errno,$error,2);
 if($socket){stream_set_timeout($socket,12);$write=function(string $data)use($socket){$at=0;while($at<strlen($data)){$n=fwrite($socket,substr($data,$at));if(!$n)throw new RuntimeException('Scanner stream interrupted');$at+=$n;}};
  try{$write("zINSTREAM\0");foreach(str_split($bytes,65536) as $chunk)$write(pack('N',strlen($chunk)).$chunk);$write(pack('N',0));$response=stream_get_contents($socket,512);if(str_contains($response,'FOUND'))fail(422,'The file was rejected by the local malware scanner. Choose a different file.');if(str_contains($response,'stream: OK'))$scan='clean';}finally{fclose($socket);}
 }
 return $scan;
}
function private_upload(array $b):array {
 $bytes=base64_decode(required($b,'data',8000000),true);
 if($bytes===false||strlen($bytes)>5000000||strlen($bytes)<20)fail(422,'Use a JPEG, PNG or plain PDF up to 5 MB.');
 $mime=(new finfo(FILEINFO_MIME_TYPE))->buffer($bytes);
 if(!in_array($mime,['image/jpeg','image/png','application/pdf']))fail(422,'Only JPEG, PNG and PDF documents are accepted.');
 if(($b['kind']??'')==='profile_photo'&&!in_array($mime,['image/jpeg','image/png']))fail(422,'A profile photo must be a JPEG or PNG image.');
 if($mime==='application/pdf'&&preg_match('/\/JavaScript|\/JS\b|\/Launch|\/EmbeddedFile|\/OpenAction/i',$bytes))fail(422,'Upload a plain PDF without embedded scripts or files.');
 if($mime!=='application/pdf'){$size=@getimagesizefromstring($bytes);if(!$size||$size[0]*$size[1]>25000000)fail(422,'Use a valid image with at most 25 million pixels.');}
 $scan=scan_bytes($bytes);
 $key=identifier();$dir=private_storage().'/documents';if(!is_dir($dir))mkdir($dir,0700,true);
 $encrypted=encrypt_value($bytes);if(file_put_contents($dir.'/'.$key,$encrypted,LOCK_EX)!==strlen($encrypted))fail(503,'Private file storage is unavailable.');
 return ['key'=>$key,'mime'=>$mime,'checksum'=>hash('sha256',$bytes),'scan_status'=>$scan];
}
function upload_action(string $action,array $b,array $u):?array {
 if($action==='case-attachment'){
  $case=row('SELECT * FROM rs_cases WHERE id=? FOR UPDATE',[required($b,'id',32)])??fail(404,'Case not found.');case_access($u,$case);version_guard($case,$b);
  if((int)$case['user_id']!==$u['id']&&(int)$case['owner_id']!==$u['id'])fail(409,'Claim the case before adding evidence.');
  $upload=private_upload($b);$id=identifier();sql('INSERT INTO rs_attachments(id,case_id,owner_id,storage_key,mime,checksum,scan_status) VALUES(?,?,?,?,?,?,?)',[$id,$case['id'],$u['id'],$upload['key'],$upload['mime'],$upload['checksum'],$upload['scan_status']]);sql('UPDATE rs_cases SET version=version+1,updated_at=UTC_TIMESTAMP() WHERE id=?',[$case['id']]);audit($u['id'],'case.attachment',$case['id'],'Encrypted evidence submitted; malware scan '.$upload['scan_status']);return ['ok'=>true,'attachment_id'=>$id,'scan_status'=>$upload['scan_status']];
 }
 return null;
}
