import urllib.request, json
urls=['https://download.bbbike.org/osm/bbbike/Dhaka/','https://api.github.com/repos/graphhopper/graphhopper/releases/tags/11.1']
for url in urls:
 try:
  data=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RideShare-development'}),timeout=30).read()
  if 'api.github' in url:
   print(json.dumps([(a['name'],a['size'],a['browser_download_url']) for a in json.loads(data)['assets']]))
  else: print(data.decode()[:7000])
 except Exception as e: print(type(e).__name__,str(e))