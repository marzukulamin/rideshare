"""Stage versioned app artifacts only. Reference footage and private runtime files are excluded."""
from pathlib import Path
import hashlib,json,shutil,re
from build_sources import source_sha
root=Path(__file__).resolve().parents[1];target=root/'release/site';target.mkdir(parents=True,exist_ok=True)
version=re.search(r'^version:\s*(\S+)',(root/'mobile/pubspec.yaml').read_text(encoding='utf-8'),re.M).group(1)
name=version.split('+')[0];meta=root/'.local/build-metadata.json';metadata=json.loads(meta.read_text(encoding='utf-8-sig')) if meta.exists() else {}
web=root/'mobile/build/web';apk=root/'mobile/build/app/outputs/flutter-apk/app-release.apk'
if not (web/'main.dart.js').is_file():raise SystemExit('Build Flutter web before staging.')
webmeta=metadata.get('web',{});androidmeta=metadata.get('android',{})
current_source=source_sha()
if webmeta.get('sourceSha256')!=current_source or (apk.exists() and androidmeta.get('sourceSha256')!=current_source):raise SystemExit('Active sources do not match both built artifacts; rebuild before staging.')
def digest(path):
 with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
if webmeta.get('version')!=version or webmeta.get('sha256')!=digest(web/'main.dart.js'):raise SystemExit('Web build metadata does not match the current artifact; run tools/build.ps1.')
if apk.exists() and (androidmeta.get('version')!=version or androidmeta.get('sha256')!=digest(apk)):raise SystemExit('APK build metadata does not match the current artifact; rebuild Android.')
# Keep obsolete captures/APKs privately recoverable, outside the public handoff.
archive=root/'.local/archive/releases';archive.mkdir(parents=True,exist_ok=True)
for relative in ['demo','downloads','media']:
 previous=target/relative
 if previous.exists():
  if not previous.resolve().is_relative_to((root/'release').resolve()):raise SystemExit('Staging path escapes the release workspace.')
  saved=archive/(relative+'-'+str(__import__('time').time_ns()))
  if not saved.resolve().is_relative_to(root.resolve()):raise SystemExit('Archive destination escapes this workspace.')
  shutil.move(str(previous),str(saved))
shutil.copytree(web,target/'demo')
record={'version':version,'minimumAndroid':'7.0','webBuiltAt':webmeta['builtAt'],'backend':androidmeta.get('backend'),'builtAt':androidmeta.get('builtAt'),'localDeviceRequiresAdbReverse':androidmeta.get('backend','').startswith('http://127.0.0.1')}
if apk.exists():
 downloads=target/'downloads';downloads.mkdir(exist_ok=True);filename=f'rideshare-{name}.apk';shutil.copy2(apk,downloads/filename)
 record.update(apk='/downloads/'+filename,apkSizeMb=round(apk.stat().st_size/1024/1024,1),sha256=hashlib.file_digest(apk.open('rb'),'sha256').hexdigest())
# Capture metadata must match this exact APK hash. Old walkthroughs never become current by renaming.
capture=root/'.local/capture-v3';capturemeta=capture/'capture.json';media=target/'media';media.mkdir(exist_ok=True)
if capturemeta.exists():
 captured=json.loads(capturemeta.read_text(encoding='utf-8'))
 if captured.get('apkSha256')==record.get('sha256'):
  if captured.get('sourceSha256')!=current_source:raise SystemExit('Walkthrough source fingerprint is missing or stale; run tools/verify_native_video.py.')
  for filename,key in [('rideshare-walkthrough.mp4','videoSha256'),('rideshare-walkthrough.vtt','captionsSha256'),('walkthrough-transcript.txt','transcriptSha256')]:
   if not (capture/filename).is_file() or captured.get(key)!=digest(capture/filename):raise SystemExit('Walkthrough bytes do not match verified metadata; run tools/verify_native_video.py.')
  for filename in ['rideshare-walkthrough.mp4','rideshare-walkthrough.vtt','walkthrough-transcript.txt']:
   if not (capture/filename).exists():raise SystemExit('Matching walkthrough requires video, captions and transcript.')
   shutil.copy2(capture/filename,media/filename)
  record.update(video='/media/rideshare-walkthrough.mp4',captions='/media/rideshare-walkthrough.vtt',transcript='/media/walkthrough-transcript.txt',videoSha256=captured['videoSha256'],captureLabel=captured['label'])
# An explicitly published earlier walkthrough may accompany a newer app,
# with its original version/hash retained rather than claimed as current evidence.
published=root/'media';publishedmeta=published/'walkthrough.json'
if 'video' not in record and publishedmeta.is_file():
 captured=json.loads(publishedmeta.read_text(encoding='utf-8'))
 if not captured.get('recordedVersion') or not captured.get('apkSha256'):raise SystemExit('Published walkthrough requires its original version and APK hash.')
 for filename,key in [('rideshare-walkthrough.mp4','videoSha256'),('rideshare-walkthrough.vtt','captionsSha256'),('walkthrough-transcript.txt','transcriptSha256')]:
  if not (published/filename).is_file() or digest(published/filename)!=captured.get(key):raise SystemExit('Published walkthrough bytes do not match verified metadata.')
  shutil.copy2(published/filename,media/filename)
 shutil.copy2(publishedmeta,media/'walkthrough.json')
 record.update(video='/media/rideshare-walkthrough.mp4',captions='/media/rideshare-walkthrough.vtt',transcript='/media/walkthrough-transcript.txt',videoSha256=captured['videoSha256'],captureLabel=captured['label'],walkthroughRecordedVersion=captured['recordedVersion'],walkthroughApkSha256=captured['apkSha256'],walkthroughMatchesCurrentApk=captured['apkSha256']==record.get('sha256'))
(target/'release.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print('Staged RideShare',version,'app artifacts. No portfolio page included.')
