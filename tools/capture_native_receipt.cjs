// Re-record the verified completed receipt in portrait, without another payment.
const u=require('./android_ui.cjs'),fs=require('fs'),cp=require('child_process');
(async()=>{
 u.command('shell','am','start','-W','-n',u.pkg+'/.MainActivity');await u.wait(2500);
 await u.click(/^Activity/,{scroll:false});await u.click(/^Dhanmondi Lake ·/,{scroll:false});
 const screen=u.nodes(),bounds=screen.map(n=>(n.bounds||'').match(/\d+/g)?.map(Number)).filter(v=>v?.length===4);
 if(Math.max(...bounds.map(v=>v[2]))>=Math.max(...bounds.map(v=>v[3])))throw Error('Receipt must be in portrait before recording');
 const receipt=JSON.parse(cp.execFileSync('E:/xamp/php/php.exe',['tools/native_receipt_evidence.php'],{cwd:u.root,encoding:'utf8'}));
 if(receipt.payment_status!=='collected')throw Error('Cash is not independently confirmed');
 let prior='';try{prior=u.command('shell','pidof','screenrecord').trim()}catch{}if(prior)throw Error('Another recorder is active');
 const remote='/sdcard/rideshare-portrait-receipt.mp4',startedAt=new Date().toISOString();
 cp.spawn(u.adb,['-s',u.serial,'shell','screenrecord','--bit-rate','6000000','--time-limit','20',remote],{stdio:'ignore',windowsHide:true});await u.wait(1000);
 const pid=u.command('shell','pidof','screenrecord').trim();if(!/^\d+$/.test(pid))throw Error('Own recorder missing');
 try{await u.wait(4000);u.command('shell','input','swipe','540','1750','540','750','800');await u.wait(5500);u.screenshot('native-customer-portrait-receipt');}
 finally{u.command('shell','kill','-2',pid);await u.wait(1200);u.command('pull',remote,u.root+'/.local/capture-v3/customer-receipt.mp4');u.command('shell','rm',remote);}
 const sources=JSON.parse(fs.readFileSync(u.root+'/.local/capture-v3/sources.json'));sources.push({name:'customer-receipt',device:u.serial,label:'Samsung SM_S938B · native Android · collected receipt',startedAt,endedAt:new Date().toISOString(),apkSha256:JSON.parse(fs.readFileSync(u.root+'/.local/build-metadata.json')).android.sha256});
 fs.writeFileSync(u.root+'/.local/capture-v3/sources.json',JSON.stringify(sources,null,2));console.log('PASS Portrait receipt records already-confirmed cash and durable history');
})().catch(e=>{console.error(e.message);process.exit(1)});
