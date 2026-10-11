const u=require('./android_ui.cjs'),fs=require('fs'),cp=require('child_process');
(async()=>{
 if(process.env.RIDESHARE_RECEIPT_OPEN!=='1'){
 u.command('shell','am','start','-W','-n',u.pkg+'/.MainActivity');await u.wait(2500);
 if(!u.nodes().some(n=>n.clickable==='true'&&/^Activity/.test(n.text||n['content-desc']||'')))await u.click('Back',{scroll:false});
 await u.click(/^Activity/,{scroll:false});await u.click(/^Dhanmondi Lake ·/,{scroll:false});}
 let visible=false;for(let i=0;i<14;i++){const n=u.nodes().find(n=>/^Confirm cash paid/.test(n.text||n['content-desc']||''));if(n){visible=true;break;}u.command('shell','input','swipe','540','1750','540','350','500');await u.wait(250);}if(!visible)throw Error('Customer cash confirmation unavailable');
 let prior='';try{prior=u.command('shell','pidof','screenrecord').trim()}catch{}if(prior)throw Error('Another recorder is active');const remote='/sdcard/rideshare-final-receipt.mp4',startedAt=new Date().toISOString();const p=cp.spawn(u.adb,['-s',u.serial,'shell','screenrecord','--bit-rate','6000000','--time-limit','30',remote],{stdio:'ignore',windowsHide:true});await u.wait(1000);const pid=u.command('shell','pidof','screenrecord').trim();if(!/^\d+$/.test(pid))throw Error('Recorder missing');
 try{await u.click(/^Confirm cash paid/,{scroll:false});await u.wait(7000);u.screenshot('native-customer-receipt');}finally{u.command('shell','kill','-2',pid);await u.wait(1200);u.command('pull',remote,u.root+'/.local/capture-v3/customer-receipt.mp4');u.command('shell','rm',remote);}
 const sources=JSON.parse(fs.readFileSync(u.root+'/.local/capture-v3/sources.json'));sources.push({name:'customer-receipt',device:u.serial,label:'Samsung SM_S938B · native Android',startedAt,endedAt:new Date().toISOString(),apkSha256:JSON.parse(fs.readFileSync(u.root+'/.local/build-metadata.json')).android.sha256});fs.writeFileSync(u.root+'/.local/capture-v3/sources.json',JSON.stringify(sources,null,2));
 cp.execFileSync('E:/xamp/php/php.exe',['tools/native_receipt_evidence.php','verify'],{cwd:u.root,stdio:'pipe'});console.log('PASS Native customer independent cash confirmation and durable history');
})().catch(e=>{console.error(e.message);process.exit(1)});
