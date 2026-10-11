"""Pinned development downloads. No app-runtime external request is introduced."""
from pathlib import Path
import urllib.request, hashlib, json, time
root=Path(__file__).resolve().parents[1]
directory=root/'.local/routing';directory.mkdir(parents=True,exist_ok=True)
sources=[('bangladesh.osm.pbf','https://download.geofabrik.de/asia/bangladesh-261009.osm.pbf'),('graphhopper-web-11.1.jar','https://github.com/graphhopper/graphhopper/releases/download/11.1/graphhopper-web-11.1.jar')]
manifest=[]
for name,url in sources:
 target=directory/name
 if not target.is_file():
  print('Downloading',name,flush=True)
  request=urllib.request.Request(url,headers={'User-Agent':'RideShare development map importer'})
  with urllib.request.urlopen(request,timeout=60) as response,(directory/(name+'.part')).open('wb') as output:
   total=int(response.headers.get('Content-Length','0'));count=0;last=time.monotonic()
   while chunk:=response.read(1024*1024):
    output.write(chunk);count+=len(chunk)
    if time.monotonic()-last>20:print(name,round(count/1024/1024),'/ ',round(total/1024/1024),'MiB',flush=True);last=time.monotonic()
  (directory/(name+'.part')).replace(target)
 manifest.append({'file':name,'url':url,'sha256':hashlib.file_digest(target.open('rb'),'sha256').hexdigest(),'bytes':target.stat().st_size})
(directory/'sources.json').write_text(json.dumps(manifest,indent=2))
print('Pinned routing downloads saved.',flush=True)
