const fs=require('fs');
const path=require('path');
const sharp=require('C:/Users/ASUS/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(__dirname,'..');
const svg=fs.readFileSync(path.join(root,'public/assets/mark.svg'),'utf8').replace('#c8f36a','#b9f5ce').replace('#10160a','#101211');
(async()=>{
  for(const size of [192,512]){
    for(const name of [`Icon-${size}.png`,`Icon-maskable-${size}.png`])
      await sharp(Buffer.from(svg)).resize(size,size).png().toFile(path.join(root,'mobile/web/icons',name));
  }
  await sharp(Buffer.from(svg)).resize(32,32).png().toFile(path.join(root,'mobile/web/favicon.png'));
  for(const [density,size] of Object.entries({mdpi:48,hdpi:72,xhdpi:96,xxhdpi:144,xxxhdpi:192})){
    await sharp(Buffer.from(svg)).resize(size,size).png().toFile(path.join(root,`mobile/android/app/src/main/res/mipmap-${density}/ic_launcher.png`));
  }
  console.log('Generated original RideShare launcher and browser icons.');
})().catch(e=>{console.error(e);process.exit(1)});
