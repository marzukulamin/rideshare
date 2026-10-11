const CACHE_NAME = 'rideshare-shell-v1';
const SHELL = ['/', '/assets/app.css', '/assets/app.js', '/manifest.json', '/assets/mark.svg'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(SHELL)).then(()=>self.skipWaiting())));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE_NAME).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{
  const url=new URL(event.request.url);
  if(url.pathname.startsWith('/api.php')||url.origin!==self.location.origin)return;
  if(event.request.method!=='GET')return;
  event.respondWith(fetch(event.request).then(response=>{if(response.ok){const copy=response.clone();caches.open(CACHE_NAME).then(cache=>cache.put(event.request,copy));}return response;}).catch(()=>caches.match(event.request).then(response=>response||caches.match('/'))));
});
