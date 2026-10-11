const ui=require('./android_ui.cjs');
(async()=>{await ui.click(/^Share driver location/,{scroll:false});await ui.wait(1000);ui.command('emu','geo','fix','90.3897','23.7581');await ui.wait(1800);console.log(JSON.stringify(ui.summary()));ui.screenshot('emulator-driver-tracking');})().catch(e=>{console.error(e.message);process.exit(1)});
