package com.rideshare.portfolio.rideshare_showcase

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class MainActivity : FlutterActivity(){
 override fun configureFlutterEngine(engine:FlutterEngine){super.configureFlutterEngine(engine)
  MethodChannel(engine.dartExecutor.binaryMessenger,"rideshare/driver_transport").setMethodCallHandler{call,result->
   when(call.method){
    "start"->{if(checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED){result.error("permission","Precise location permission is required.",null)}else{
      if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),1401)
      val intent=Intent(this,DriverLocationService::class.java).putExtra("base",call.argument<String>("base")).putExtra("token",call.argument<String>("token"))
      if(Build.VERSION.SDK_INT>=26)startForegroundService(intent)else startService(intent);result.success(true)
    }}
    "status"->{result.success(DriverLocationService.active)}
    "stop"->{stopService(Intent(this,DriverLocationService::class.java));result.success(true)}
    else->result.notImplemented()
   }
  }
 }
}
