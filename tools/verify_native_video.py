"""Verify the real native export and bind its bytes to the tested APK."""
from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parent.parent;capture=root/'.local/capture-v3'
probe=Path(r'C:\Users\ASUS\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0-full_build\bin\ffprobe.exe')
def digest(p):
    with p.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
meta=json.loads((root/'.local/build-metadata.json').read_text(encoding='utf-8-sig'));record=json.loads((capture/'capture.json').read_text())
if record['apkSha256']!=meta['android']['sha256']:raise SystemExit('Capture APK does not match current build.')
video=capture/'rideshare-walkthrough.mp4';info=json.loads(subprocess.check_output([str(probe),'-v','error','-show_streams','-show_format','-of','json',str(video)]))
streams=info['streams'];v=next(s for s in streams if s['codec_type']=='video')
if (v['width'],v['height'],v['r_frame_rate'],int(v['nb_frames']))!=(1920,1080,'30/1',1350) or abs(float(info['format']['duration'])-45)>.05:raise SystemExit('Export does not match the 45-second 1080p/30fps brief.')
if any(s['codec_type']=='audio' for s in streams):raise SystemExit('Silent walkthrough must not contain unintended audio.')
for source in record['sourceRecordings']:
    if source['apkSha256']!=record['apkSha256']:raise SystemExit('Source recording is stale.')
captions=(capture/'rideshare-walkthrough.vtt').read_text(encoding='utf-8');transcript=(capture/'walkthrough-transcript.txt').read_text(encoding='utf-8')
if not captions.startswith('WEBVTT') or captions.count('-->')!=5 or '36–45s' not in transcript:raise SystemExit('Captions or transcript are incomplete.')
record.update(videoSha256=digest(video),captionsSha256=digest(capture/'rideshare-walkthrough.vtt'),transcriptSha256=digest(capture/'walkthrough-transcript.txt'),width=1920,height=1080,fps=30,sourceSha256=meta['android']['sourceSha256'])
(capture/'capture.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
(root/'.local/verification/video.json').write_text(json.dumps({'passed':True,'durationSeconds':45,'width':1920,'height':1080,'fps':30,'videoSha256':record['videoSha256'],'apkSha256':record['apkSha256'],'captions':5},indent=2))
print('Verified 45-second 1080p/30fps native export, silent audio, five captions and exact APK binding.')
