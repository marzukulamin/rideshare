// Emulator-only stationary GPS feed. No phone location is mocked.
const cp=require('child_process'),path=require('path');
const adb=path.resolve(__dirname,'../.tools/android-sdk/platform-tools/adb.exe');
function update(){cp.execFileSync(adb,['-s','emulator-5556','emu','geo','fix','90.3897','23.7581'],{stdio:'ignore',timeout:8000});}
update();const timer=setInterval(update,8000);setTimeout(()=>{clearInterval(timer);process.exit(0)},240000);
