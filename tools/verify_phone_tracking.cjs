const u=require('./android_ui.cjs'),fs=require('fs'),cp=require('child_process');let checks=0;
function status(){return JSON.parse(cp.execFileSync('E:/xamp/php/php.exe',['tools/native_driver_status.php','driver_secondary'],{cwd:u.root,encoding:'utf8'}));}
function check(value,label){if(!value)throw Error('FAILED: '+label);checks++;console.log('PASS '+label);}
(async()=>{
 u.command('shell','am','force-stop',u.pkg);u.command('shell','am','start','-W','-n',u.pkg+'/.MainActivity');await u.wait(2500);
 if(u.nodes().some(n=>/^Account/.test(n['content-desc']||n.text||''))){await u.click(/^Account/,{scroll:false});await u.click('Sign out');}
 const a=JSON.parse(fs.readFileSync(u.root+'/.local/backend/test-accounts.json','utf8')).driver_secondary;
 await u.type('Phone number',a.phone);await u.type('Password',a.password);u.command('shell','input','keyevent','4');await u.click('Sign in',{scroll:false});await u.wait(1800);
 await u.click(/^Drive/,{scroll:false});
 for(const permission of ['ACCESS_FINE_LOCATION','ACCESS_COARSE_LOCATION','POST_NOTIFICATIONS'])u.command('shell','pm','grant',u.pkg,'android.permission.'+permission);
 let controls=u.nodes();if(controls.some(n=>/^Offline(?:\s|$)/.test(n['content-desc']||n.text||'')))await u.click(/^Offline(?:\s|$)/,{scroll:false});
 await u.click(/^Share driver location/);await u.wait(18000);let before=status();
 check(u.command('shell','dumpsys','activity','services',u.pkg).includes('isForeground=true foregroundId=4101'),'Samsung runs a visible native location foreground service');
 u.command('shell','input','keyevent','3');await u.wait(30000);let background=status();
 check(background.heartbeat_at>before.heartbeat_at,'Physical Samsung heartbeat advances while RideShare is backgrounded');
 u.command('reverse','--remove','tcp:8098');await u.wait(45000);await u.wait(30000);let disconnected=status();
 check(disconnected.receiving_offers===false,'Disconnected physical driver is excluded from new offers after freshness expiry');
 u.command('reverse','tcp:8098','tcp:8098');await u.wait(22000);let recovered=status();
 check(recovered.heartbeat_at>disconnected.heartbeat_at,'Native service recovers its heartbeat when the backend connection returns');
 u.command('shell','am','start','-W','-n',u.pkg+'/.MainActivity');await u.wait(1500);await u.click(/^Share driver location/);await u.wait(1000);
 check(!u.command('shell','dumpsys','activity','services',u.pkg).includes('.DriverLocationService c:'),'Turning tracking off stops the native foreground service');
 fs.writeFileSync(u.root+'/.local/verification/phone-tracking.json',JSON.stringify({passed:checks,time:new Date().toISOString(),device:u.serial,apkSha256:JSON.parse(fs.readFileSync(u.root+'/.local/build-metadata.json')).android.sha256,foreground:before,background,disconnected,recovered,limitations:['No lock/battery-saver/killed-process guarantee; physical GPS freshness recorded independently.']},null,2));
 await u.click(/^Account/,{scroll:false});await u.click('Sign out');
})().catch(e=>{try{u.command('reverse','tcp:8098','tcp:8098')}catch{}console.error(e.message);process.exit(1)});
