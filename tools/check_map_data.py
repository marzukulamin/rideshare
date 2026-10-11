import urllib.request
for url in ['https://download.geofabrik.de/asia/bangladesh-latest.osm.pbf','https://download.bbbike.org/osm/bbbike/Dacca/Dacca.osm.pbf','https://download.geofabrik.de/asia/bangladesh.html']:
 try:
  r=urllib.request.urlopen(urllib.request.Request(url,method='HEAD',headers={'User-Agent':'RideShare-development'}),timeout=20)
  print(url,r.status,r.headers.get('Content-Length'),r.headers.get('Last-Modified'))
 except Exception as e: print(url,type(e).__name__,str(e))