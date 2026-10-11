package com.rideshare.portfolio.rideshare_showcase

import android.Manifest
import android.app.*
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** First-party transport runs with a visible location foreground service.
 * No restart after process death: the server expires reachability and retains trip ownership.
 */
class DriverLocationService : Service(), LocationListener {
 companion object {@Volatile var active=false}
 private val scheduler=Executors.newSingleThreadScheduledExecutor()
 private lateinit var manager:LocationManager
 private var base="";private var token="";@Volatile private var observation:Location?=null
 private var scheduled=false
 private val notified=mutableSetOf<String>()
 override fun onBind(intent:Intent?)=null
 override fun onCreate(){super.onCreate();manager=getSystemService(LOCATION_SERVICE) as LocationManager
  val notifications=getSystemService(NOTIFICATION_SERVICE) as NotificationManager
  if(Build.VERSION.SDK_INT>=26)notifications.createNotificationChannel(NotificationChannel("driver_tracking","Driver location",NotificationManager.IMPORTANCE_LOW))
  if(Build.VERSION.SDK_INT>=26)notifications.createNotificationChannel(NotificationChannel("ride_offers","Ride offers",NotificationManager.IMPORTANCE_HIGH))
 }
 private fun builder(channel:String):Notification.Builder=if(Build.VERSION.SDK_INT>=26)Notification.Builder(this,channel)else Notification.Builder(this)
 private fun pending():PendingIntent=PendingIntent.getActivity(this,0,Intent(this,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
 override fun onStartCommand(intent:Intent?,flags:Int,startId:Int):Int{
  base=intent?.getStringExtra("base")?:"";token=intent?.getStringExtra("token")?:""
  val uri=try{URI(base)}catch(e:Exception){stopSelf();return START_NOT_STICKY}
  if(token.isEmpty()||(uri.scheme!="https"&&!(uri.scheme=="http"&&uri.host in listOf("127.0.0.1","localhost")))){stopSelf();return START_NOT_STICKY}
  if(checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED){stopSelf();return START_NOT_STICKY}
  val notice=builder("driver_tracking").setSmallIcon(R.mipmap.ic_launcher).setContentTitle("RideShare driver location").setContentText("Sharing location while available or on your assigned ride").setContentIntent(pending()).setOngoing(true).build()
  if(Build.VERSION.SDK_INT>=29)startForeground(4101,notice,ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)else startForeground(4101,notice)
  // A parked driver still needs fresh observations. A distance threshold would
  // stop updates while stationary and wrongly make that driver ineligible.
  try{manager.requestLocationUpdates(LocationManager.GPS_PROVIDER,10000L,0f,this,Looper.getMainLooper())}catch(e:Exception){stopSelf();return START_NOT_STICKY}
  if(!scheduled&&!scheduler.isShutdown){scheduled=true;scheduler.scheduleWithFixedDelay({tick()},0,15,TimeUnit.SECONDS)}
  active=true
  return START_NOT_STICKY
 }
 override fun onLocationChanged(location:Location){observation=location}
 private fun request(action:String,body:JSONObject?=null):JSONObject{
  val c=URI(base).resolve("api.php?action=$action").toURL().openConnection() as HttpURLConnection
  c.connectTimeout=10000;c.readTimeout=10000;c.instanceFollowRedirects=false
  c.setRequestProperty("Authorization","Bearer $token")
  try{
   if(body!=null){c.requestMethod="POST";c.doOutput=true;c.setRequestProperty("Content-Type","application/json");c.setRequestProperty("Idempotency-Key",java.util.UUID.randomUUID().toString());c.outputStream.use{it.write(body.toString().toByteArray(Charsets.UTF_8))}}
   if(c.responseCode==401||c.responseCode==403){Handler(Looper.getMainLooper()).post{stopSelf()};throw IllegalStateException("Access revoked")}
   if(c.responseCode!=200)throw IllegalStateException("Unconfirmed response")
   return JSONObject(c.inputStream.bufferedReader().use{it.readText()})
  }finally{c.disconnect()}
 }
 private fun tick(){try{
  val heartbeat=JSONObject();val p=observation
  if(p!=null&&System.currentTimeMillis()-p.time<60000){heartbeat.put("lat",p.latitude).put("lng",p.longitude).put("accuracy",p.accuracy.toDouble()).put("observed_at",p.time/1000)}
  request("driver-heartbeat",heartbeat)
  val overview=request("driver-overview");val profile=overview.optJSONObject("profile")
  if(profile?.optInt("desired_online",0)==0&&overview.isNull("active_trip_id")){Handler(Looper.getMainLooper()).post{stopSelf()};return}
  if(!overview.optBoolean("offer_notifications",true))return
  val offers=overview.optJSONArray("offers")?:return
  for(i in 0 until offers.length()){val offer=offers.getJSONObject(i);val id=offer.getString("id")
   if(notified.add(id)&& (Build.VERSION.SDK_INT<33||checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED)){
    val notification=builder("ride_offers").setSmallIcon(R.mipmap.ic_launcher).setContentTitle("New RideShare offer").setContentText("Open the app to review before the offer expires").setContentIntent(pending()).setAutoCancel(true).setVisibility(Notification.VISIBILITY_PRIVATE).build()
    (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(id.hashCode(),notification)
   }
  }
 }catch(ignored:Exception){/* Keep last confirmed state. Server reachability expires without an acknowledgement. */}}
 override fun onDestroy(){active=false;scheduler.shutdownNow();try{manager.removeUpdates(this)}catch(ignored:Exception){};token="";observation=null;super.onDestroy()}
}
