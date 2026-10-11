"""Install the official standalone ClamAV scanner. Signature updates are explicit maintenance."""
from pathlib import Path
import urllib.request, json, zipfile, hashlib, subprocess, time
root=Path(__file__).resolve().parents[1];local=root/'.tools/clamav';local.mkdir(parents=True,exist_ok=True)
url='https://github.com/Cisco-Talos/clamav/releases/download/clamav-1.5.4/clamav-1.5.4.win.x64.zip'
archive=local/'clamav-1.5.4.zip'
if not archive.exists():
 with urllib.request.urlopen(url,timeout=60) as response,archive.with_suffix('.part').open('wb') as out:
  count=0;last=time.monotonic()
  while chunk:=response.read(1024*1024):
   out.write(chunk);count+=len(chunk)
   if time.monotonic()-last>20:print('Scanner download',round(count/1024/1024),'MiB',flush=True);last=time.monotonic()
 archive.with_suffix('.part').replace(archive)
with zipfile.ZipFile(archive) as z:
 for entry in z.infolist():
  if not (local/entry.filename).resolve().is_relative_to(local.resolve()):raise RuntimeError('Unsafe archive path')
 z.extractall(local)
binary=next(local.rglob('freshclam.exe'));directory=binary.parent
database=root/'.local/scanner-db';database.mkdir(parents=True,exist_ok=True)
config=root/'.local/freshclam.conf'
config.write_text(f'DatabaseDirectory "{database}"\nDatabaseMirror database.clamav.net\nScriptedUpdates yes\nConnectTimeout 15\nReceiveTimeout 60\n',encoding='utf-8')
(local/'source.json').write_text(json.dumps({'url':url,'sha256':hashlib.file_digest(archive.open('rb'),'sha256').hexdigest(),'version':'1.5.4'},indent=2))
print('Updating local signatures using official FreshClam',flush=True)
with (root/'.local/scanner-maintenance.log').open('w',encoding='utf-8') as log:
 subprocess.run([str(binary),f'--config-file={config}'],check=True,timeout=300,stdout=log,stderr=subprocess.STDOUT)
print('Standalone scanner ready',flush=True)
