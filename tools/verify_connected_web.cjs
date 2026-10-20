const path=require('path'),fs=require('fs'),crypto=require('crypto');
const {chromium}=require('C:/Users/ASUS/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
let browser;
const root=path.resolve(__dirname,'..'),base='http://127.0.0.1:8098';
const accounts=JSON.parse(fs.readFileSync(path.join(root,'.local/backend/test-accounts.json'),'utf8'));
function totp(secret){let bits='';for(const c of secret)bits+='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'.indexOf(c).toString(2).padStart(5,'0');const key=Buffer.from(bits.match(/.{8}/g).map(x=>parseInt(x,2)));const b=Buffer.alloc(8);b.writeBigUInt64BE(BigInt(Math.floor(Date.now()/30000)));const h=crypto.createHmac('sha1',key).update(b).digest();const at=h[19]&15;return String((h.readUInt32BE(at)&0x7fffffff)%1000000).padStart(6,'0');}
(async()=>{
 browser=await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
 const external=[],errors=[],evidence=path.join(root,'.local/verification');fs.mkdirSync(evidence,{recursive:true});
 async function pageFor(role,viewport={width:390,height:844}){
  const context=await browser.newContext({viewport,geolocation:{latitude:23.7581,longitude:90.3897,accuracy:10},permissions:['geolocation']});
  const page=await context.newPage();page.on('request',r=>{if(!r.url().startsWith(base+'/')&&!r.url().startsWith('data:')&&!r.url().startsWith('blob:'))external.push(r.url().split('?')[0]);});page.on('pageerror',e=>errors.push(e.message));
  await page.goto(base+'/demo/');await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());await page.getByRole('button',{name:'Sign in with an account',exact:true}).click();await page.getByRole('button',{name:'Sign in',exact:true}).waitFor({timeout:30000});
  await page.getByRole('textbox',{name:'Phone number',exact:true}).click();await page.keyboard.insertText(accounts[role].phone);await page.getByRole('textbox',{name:'Password',exact:true}).click();await page.keyboard.insertText(accounts[role].password);
  if(accounts[role].totpSecret){await page.getByRole('textbox',{name:'Staff authentication code'}).click();await page.keyboard.insertText(totp(accounts[role].totpSecret));}
  await page.getByRole('button',{name:'Sign in',exact:true}).click();try{await page.getByRole('button',{name:/Inbox/}).first().waitFor({timeout:10000});}catch(e){await page.screenshot({path:path.join(evidence,role+'-login-result.png')});console.log('Login result button labels: '+JSON.stringify(await page.getByRole('button').allTextContents()));console.log('Visible errors: '+JSON.stringify(await page.locator('flt-semantics').filter({hasText:/incorrect|expired|failed|attempts|security token|unavailable/}).allTextContents()));throw e;}console.log('Authenticated '+role+' browser context');return page;
 }
 const customer=await pageFor('customer'),driver=await pageFor('driver'),staff=await pageFor('support',{width:1280,height:900});
 await customer.getByRole('button',{name:/^(Home|হোম)/}).or(customer.getByRole('tab',{name:/^(Home|হোম)/})).first().click();
 await customer.screenshot({path:path.join(evidence,'customer-home.png')});await driver.screenshot({path:path.join(evidence,'driver-home.png')});await staff.screenshot({path:path.join(evidence,'staff-home.png')});
 await customer.getByRole('button',{name:/^(Where to\?|কোথায় যাবেন\?)$/}).click();
 fs.writeFileSync(path.join(evidence,'browser-probe.json'),JSON.stringify({customer:await customer.locator('body').ariaSnapshot(),driver:await driver.locator('body').ariaSnapshot(),staff:await staff.locator('body').ariaSnapshot(),external,errors},null,2));
 console.log('Connected customer, driver and staff sessions opened in separate browser contexts. Probe saved.');
 if(external.length||errors.length)throw Error('Unexpected runtime request or browser error');
 await browser.close();
})().catch(async e=>{console.error(e.message);if(browser)await browser.close();process.exit(1)});
