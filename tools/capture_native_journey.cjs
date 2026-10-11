const fs=require('fs'),path=require('path'),cp=require('child_process');
const root=path.resolve(__dirname,'..'),adb=path.join(root,'.tools/android-sdk/platform-tools/adb.exe'),pkg='com.rideshare.portfolio.rideshare_showcase';
const dir=path.join(root,'.local/capture-v3');fs.mkdirSync(dir,{recursive:true});
const wait=ms=>new Promise(r=>setTimeout(r,ms));const phone='R5CY23MS2SP',driver='emulator-5556';let recording,ticker;const marks=[];
function mark(label){marks.push({label,recording:recording?.name,seconds:recording?(Date.now()-Date.parse(recording.startedAt))/1000:0});fs.writeFileSync(dir+'/marks.json',JSON.stringify(marks,null,2));}
function run(serial,code){return cp.execFileSync(process.execPath,['-e',`const u=require('./tools/android_ui.cjs');(async()=>{u.command('shell','am','start','-n',u.pkg+'/.MainActivity');await u.wait(800);${code}})().catch(e=>{console.error(e.message);process.exit(1)})`],{cwd:root,env:{...process.env,RIDESHARE_DEVICE:serial},encoding:'utf8',timeout:90000});}
function cmd(serial,...args){return cp.execFileSync(adb,['-s',serial,...args],{encoding:'utf8',timeout:20000});}
async function start(serial,name){if(cmd(serial,'shell','pidof','screenrecord').trim())throw Error('A different screen recording is active');}
async function record(serial,name){let previous='';try{previous=cmd(serial,'shell','pidof','screenrecord').trim()}catch{}if(previous)throw Error('A different screen recording is active');const remote='/sdcard/rideshare-'+name+'.mp4';const proc=cp.spawn(adb,['-s',serial,'shell','screenrecord','--bit-rate','6000000','--time-limit','180',remote],{stdio:'ignore'});await wait(800);const pid=cmd(serial,'shell','pidof','screenrecord').trim();if(!/^\d+$/.test(pid))throw Error('Cannot identify our recorder');recording={serial,name,remote,pid,proc,startedAt:new Date().toISOString()};}
async function stop(){if(!recording)return;const r=recording;recording=null;cmd(r.serial,'shell','kill','-2',r.pid);await wait(1500);cmd(r.serial,'pull',r.remote,path.join(dir,r.name+'.mp4'));cmd(r.serial,'shell','rm',r.remote);const file=path.join(dir,'sources.json');const sources=fs.existsSync(file)?JSON.parse(fs.readFileSync(file)):[];sources.push({name:r.name,device:r.serial,label:r.serial===phone?'Samsung SM_S938B · native Android':'Android emulator · native Android',startedAt:r.startedAt,endedAt:new Date().toISOString(),apkSha256:JSON.parse(fs.readFileSync(root+'/.local/build-metadata.json')).android.sha256});fs.writeFileSync(file,JSON.stringify(sources,null,2));}
function state(){cp.execFileSync('E:/xamp/php/php.exe',['tools/native_fixture_state.php','customer_walkthrough'],{cwd:root,stdio:'pipe'});return JSON.parse(fs.readFileSync(root+'/.local/verification/native-customer_walkthrough-state.json'));}
(async()=>{
 const old=state().bootstrap.active_trip;const resume=process.env.RIDESHARE_RESUME==='1'&&old?.status==='matching';if(old&&!resume)throw Error('Resolve the previous isolated customer fixture before capturing again');
 if(!resume){
 run(driver,"u.command('shell','am','force-stop',u.pkg);u.command('shell','monkey','-p',u.pkg,'1');await u.wait(2000);await u.click(/^Share driver location/,{scroll:false});u.command('emu','geo','fix','90.3897','23.7581');await u.wait(16000);");
 }
 ticker=cp.spawn(process.execPath,['tools/android_stationary_fixture.cjs'],{cwd:root,stdio:'ignore',windowsHide:true});
 if(!resume){
 run(phone,"await u.click(/^Home/,{scroll:false});");
 await record(phone,'customer-booking');
 run(phone,"await u.click('Where to?',{scroll:false});await u.click(/^Choose pickup/,{scroll:false});await u.click(/^Farmgate/);await u.click('Choose destination',{scroll:false});await u.type('Search places','Dhanmondi');u.command('shell','input','keyevent','4');await u.click(/^Dhanmondi Lake/,{scroll:false});u.screenshot('phone-picker-fixed');await u.click(/^Car ·/);await u.click('Review price');u.screenshot('phone-quote');await u.wait(1200);await u.click('Request Car');await u.wait(1500);u.screenshot('phone-matching');");
 mark('matching');await stop();}
 let s=state();if(s.bootstrap.active_trip?.status!=='matching')throw Error('Native customer did not create a matching trip');const id=s.bootstrap.active_trip.id;console.log('PASS Native customer quote and real matching request');
 await record(driver,'driver-trip');
 run(driver,"u.command('emu','geo','fix','90.3897','23.7581');await u.wait(5000);await u.click('Accept ride');await u.click('Head to pickup');await u.click('Confirm arrival');u.screenshot('native-driver-arrived');");
 mark('arrival');s=state();if(s.bootstrap.active_trip.status!=='arrived')throw Error('Driver arrival was not confirmed');
 const controls=JSON.parse(run(phone,"console.log(JSON.stringify(u.summary()));u.screenshot('native-customer-pin');"));if(controls.includes('Start ride'))throw Error('Customer can start ride');console.log('PASS Native assigned-driver arrival; customer has no Start ride');
 fs.writeFileSync(dir+'/pin-input.json',JSON.stringify({pin:s.bootstrap.active_trip.pin}));
 run(driver,"const fs=require('fs');const pin=JSON.parse(fs.readFileSync(u.root+'/.local/capture-v3/pin-input.json')).pin;await u.type('Ask customer for pickup PIN',pin);u.command('shell','input','keyevent','4');await u.click('Start ride');u.screenshot('native-driver-in-progress');");
 mark('started');if(state().bootstrap.active_trip.status!=='in_progress')throw Error('Driver start did not persist');console.log('PASS Native driver PIN start');
 run(phone,"u.command('shell','am','force-stop',u.pkg);u.command('shell','monkey','-p',u.pkg,'1');await u.wait(2000);u.screenshot('native-customer-resume');await u.click(/^Your current trip/,{scroll:false});");
 run(driver,"await u.click('Complete ride');u.screenshot('native-driver-completed');await u.click('Record cash received');await u.type('Collection evidence or note','Native integration fixture cash handoff; no real funds');u.command('shell','input','keyevent','4');await u.click('Record cash received');");await stop();
 if(state().bootstrap.active_trip!==null)throw Error('Completion failed to release customer');console.log('PASS Native completion and cold-launch recovery');
 await record(phone,'customer-receipt');
 run(phone,"await u.wait(5500);await u.click(/^Confirm cash paid/);u.screenshot('native-customer-receipt');await u.wait(1200);");await stop();
 fs.writeFileSync(root+'/.local/verification/native-journey.json',JSON.stringify({passed:5,trip:id,time:new Date().toISOString(),apkSha256:JSON.parse(fs.readFileSync(root+'/.local/build-metadata.json')).android.sha256,devices:[phone,driver]},null,2));console.log('PASS Native customer independent cash confirmation');
 ticker?.kill();
})().catch(async e=>{ticker?.kill();try{await stop()}catch{}console.error(e.message);process.exit(1)});
