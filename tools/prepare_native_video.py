"""Edit genuine native recordings into an accessible, exact-build walkthrough."""
from pathlib import Path
import json,subprocess,html
root=Path(__file__).resolve().parent.parent
capture=root/'.local/capture-v3';project=capture/'composition';assets=project/'assets'
ffmpeg=Path(r'C:\Users\ASUS\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0-full_build\bin\ffmpeg.exe')
probe=ffmpeg.with_name('ffprobe.exe')
meta=json.loads((root/'.local/build-metadata.json').read_text(encoding='utf-8-sig'))['android']
journey=json.loads((root/'.local/verification/native-journey.json').read_text())
if journey['apkSha256']!=meta['sha256']:raise SystemExit('Native evidence does not match this APK.')
sources=json.loads((capture/'sources.json').read_text());latest={s['name']:s for s in sources}
for name in ['customer-booking','driver-trip','customer-receipt']:
    if latest[name]['apkSha256']!=meta['sha256']:raise SystemExit('Stale source recording.')
marks={m['label']:m['seconds'] for m in json.loads((capture/'marks.json').read_text())}
scenes=[
 ('customer-booking',0,'Book in a few taps.','Customer · Samsung Android','Choose your pickup and destination.','Database-backed places and a bundled map.'),
 ('customer-booking',24,'Review your fare.','Customer · Samsung Android','See the road fare before requesting.','Cash, service terms and your chosen vehicle.'),
 ('driver-trip',max(0,marks['arrival']-5),'Your driver handles pickup.','Driver · Android emulator','The assigned driver confirms arrival.','Separate accounts. Assigned-driver controls.'),
 ('driver-trip',max(0,marks['started']-5),'PIN checked. Ride started.','Driver · Android emulator','The driver validates the customer’s PIN.','Customer screens never expose a Start ride button.'),
 ('customer-receipt',0,'Cash confirmed. Receipt saved.','Customer · Samsung Android','Your cash confirmation is recorded.','The completed trip remains in your history.'),
]
for i,(name,start,*_) in enumerate(scenes):
    source=capture/(name+'.mp4');info=json.loads(subprocess.check_output([str(probe),'-v','error','-show_format','-of','json',str(source)]));duration=float(info['format']['duration']);start=min(start,max(0,duration-9))
    subprocess.run([str(ffmpeg),'-hide_banner','-loglevel','error','-y','-ss',str(start),'-i',str(source),'-t','9','-an','-vf','crop=iw:ih-160:0:80,scale=432:-2,setpts=PTS-STARTPTS,fps=30,tpad=stop_mode=clone:stop_duration=9','-t','9','-c:v','libx264','-g','30','-keyint_min','30','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(assets/f'scene-{i}.mp4')],check=True)
body=[];animation=[];captions=['WEBVTT',''];transcript=['RideShare — actual Android walkthrough','45 seconds; silent with on-screen descriptions.','Local development fixtures, no real money.','']
for i,(_,_,title,label,caption,detail) in enumerate(scenes):
    at=i*9
    # Registry device-frame-stage geometry/material adapted into this standalone
    # scene. The screen slot contains actual cropped recordings, never rebuilt UI.
    body.append(f'''<section class="scene" id="scene-{i}">
      <div class="copy" id="copy-{i}"><p class="label">{html.escape(label)}</p><h1>{html.escape(title)}</h1><p class="caption">{html.escape(caption)}</p><p class="detail">{html.escape(detail)}</p><div class="step">0{i+1} / 05</div></div>
      <div class="device-frame" id="device-{i}"><div class="device-screen"><video id="native-screen-{i}" class="clip" src="assets/scene-{i}.mp4" data-start="{at}" data-duration="9" data-track-index="1" muted playsinline preload="auto"></video></div></div>
    </section>''')
    animation.append(f"tl.set('#scene-{i}',{{opacity:1}},{at});tl.set('#scene-{i}',{{opacity:0}},{at+9});tl.fromTo('#device-{i}',{{y:18,scale:.94}},{{y:0,scale:1,duration:.8,ease:'power3.out'}},{at}); tl.set('#copy-{i}',{{opacity:1,y:48}},{at+.1});tl.to('#copy-{i}',{{y:0,duration:.2,ease:'power4.out'}},{at+.1});")
    def stamp(t):return f'00:00:{t:02d}.000'
    captions.extend([f'{stamp(at)} --> {stamp(at+9)}',f'{label}: {caption} {detail}',''])
    transcript.append(f'{at:02d}–{at+9:02d}s · {label}\n{title} {caption} {detail}\n')
doc='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=1920,height=1080"><title>RideShare native Android walkthrough</title><script src="assets/gsap.min.js"></script><style>
@font-face{font-family:Roboto;src:url('assets/Roboto-Regular.ttf')}*{box-sizing:border-box}html,body{margin:0;width:1920px;height:1080px;overflow:hidden;background:#101813;color:#f5fff8;font-family:Roboto,sans-serif}#root{width:100%;height:100%;position:relative;overflow:hidden;background:radial-gradient(ellipse at 78% 40%,#224034,#101813 65%)}.brand{position:absolute;left:150px;top:66px;font-size:36px;color:#a9ecc8;letter-spacing:1px}.scene{position:absolute;inset:0;opacity:0}.copy{position:absolute;left:150px;top:280px;width:860px;opacity:0}.label{font-size:26px;color:#a9ecc8;text-transform:uppercase;letter-spacing:3px;margin:0 0 26px}h1{font-size:76px;line-height:1.12;letter-spacing:-2px;margin:0 0 32px}.caption{font-size:34px;line-height:1.45;margin:0 0 16px}.detail{font-size:27px;line-height:1.5;color:#bdcfc4;max-width:800px;margin:0}.step{margin-top:48px;font-size:24px;color:#a9ecc8}.device-frame{position:absolute;left:1210px;top:65px;height:925px;aspect-ratio:9/19.5;border-radius:46px;padding:9px;background:linear-gradient(145deg,#343740,#1b1d22 42%,#111318);border:1px solid rgba(255,255,255,.22);box-shadow:0 52px 110px #070a143d,0 18px 38px #070a1438,inset 0 1px 0 #ffffff3d;transform-origin:50% 88%}.device-screen{width:100%;height:100%;position:relative;overflow:hidden;border-radius:37px;background:#101411}.device-screen video{position:absolute;inset:0;width:100%;height:100%;object-fit:contain}.footer{position:absolute;left:150px;bottom:72px;font-size:23px;line-height:1.5;color:#bdcfc4;max-width:860px}
</style></head><body><div id="root" data-composition-id="main" data-width="1920" data-height="1080" data-duration="45"><div class="brand">RideShare</div>'''+''.join(body)+'''<div class="footer">Flutter · Dart · Own PHP/MySQL backend<br>Actual native app · local test accounts</div></div><script>const tl=gsap.timeline({paused:true});'''+''.join(animation)+'''window.__timelines=window.__timelines||{};window.__timelines.main=tl;</script></body></html>'''
(project/'index.html').write_text(doc,encoding='utf-8')
(project/'BRIEF.md').write_text('''---
workflow: general-video
flow: autonomous
storyboard: false
---
The user authorized an actual native Android phone mockup walkthrough with captions and transcript for their separate portfolio website, without a portfolio page in RideShare. Use the final signed APK only. Samsung footage shows Customer; Android emulator footage shows the assigned Driver and is labeled accurately. Native recordings are local test data, never authentic passenger operations. Original charcoal/mint branding, restrained device-stage settle and text arrival, silent 45-second 1920x1080 output. Crop system bars/notifications; omit credentials and supplied Uber footage. Keep the original UI visible. Local font/GSAP; no external assets in rendering. Caption the genuine actions without inventing gestures or outcomes. Registry device-frame-stage supplies the frame material/geometry; waterfall entry and settle motion are seek-safe. User explicitly requested implementation/delivery together without repetitive approvals, so inspect the concrete preview and render under that authorization.
''',encoding='utf-8')
(capture/'rideshare-walkthrough.vtt').write_text('\n'.join(captions),encoding='utf-8')
(capture/'walkthrough-transcript.txt').write_text('\n'.join(transcript),encoding='utf-8')
(capture/'capture.json').write_text(json.dumps({'apkSha256':meta['sha256'],'label':'Actual native Android · Samsung Customer and emulator Driver · local fixtures','durationSeconds':45,'composition':'composition/index.html','sourceRecordings':[latest[n] for n in ['customer-booking','driver-trip','customer-receipt']]},indent=2),encoding='utf-8')
print('Prepared exact-build native footage, composition, captions and transcript.')

