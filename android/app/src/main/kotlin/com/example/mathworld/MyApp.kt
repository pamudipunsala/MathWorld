package com.example.mathworld

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.Log
import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustAttribution
import com.adjust.sdk.AdjustConfig
import com.adjust.sdk.LogLevel
import io.flutter.plugin.common.MethodChannel

class MyApp : Application() {
    private var methodChannel: MethodChannel? = null
    
    fun setMethodChannel(channel: MethodChannel) {
        methodChannel = channel
    }
    
    override fun onCreate() {
        super.onCreate()

        val appToken = BuildConfig.ADJUST_APP_TOKEN
        if (appToken.isEmpty()) {
            Log.e("AdjustAttribution", "❌ ADJUST_APP_TOKEN is empty! Check local.properties")
            return
        }
        
        val environment = AdjustConfig.ENVIRONMENT_PRODUCTION
        val config = AdjustConfig(this, appToken, environment)

        if (BuildConfig.DEBUG) {
            config.setLogLevel(LogLevel.VERBOSE)
        }

        config.setOnAttributionChangedListener { attribution: AdjustAttribution? ->
            attribution?.let {
                Log.d("AdjustAttribution", "✅ Attribution callback fired!")
                saveAdjustAttribution(it)
            } ?: run {
                Log.d("AdjustAttribution", "⚠️ Attribution callback fired but attribution is null")
            }
        }

        Adjust.onCreate(config)
        
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            try {
                val attribution = Adjust.getAttribution()
                attribution?.let {
                    Log.d("AdjustAttribution", "✅ Got attribution directly: $it")
                    saveAdjustAttribution(it)
                }
            } catch (e: Exception) {
                Log.d("AdjustAttribution", "⚠️ Could not get attribution directly: ${e.message}")
            }
        }, 2000)
        
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            try {
                val attribution = Adjust.getAttribution()
                attribution?.let {
                    saveAdjustAttribution(it)
                }
            } catch (e: Exception) {
                Log.d("AdjustAttribution", "⚠️ Could not retry attribution: ${e.message}")
            }
        }, 5000)
        
        registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityResumed(activity: Activity) {
                Adjust.onResume()
            }
            override fun onActivityPaused(activity: Activity) {
                Adjust.onPause()
            }
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })
    }
    
    private fun saveAdjustAttribution(attribution: AdjustAttribution) {
        val source = (attribution.network ?: "").replace(" ", "")
        val campaign = attribution.campaign ?: ""
        val adgroup = attribution.adgroup ?: ""
        val creative = attribution.creative ?: ""
        val trackerName = attribution.trackerName ?: ""
        val trackerToken = attribution.trackerToken ?: ""
        val adjustDeviceId = attribution.adid ?: ""

        Log.d("AdjustAttribution", "source=$source, campaign=$campaign, adgroup=$adgroup, creative=$creative, trackerName=$trackerName, trackerToken=$trackerToken, adjustDeviceId=$adjustDeviceId")

        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putString("flutter.adjust_source", source)
        editor.putString("flutter.adjust_campaign", campaign)
        editor.putString("flutter.adjust_adgroup", adgroup)
        editor.putString("flutter.adjust_creative", creative)
        editor.putString("flutter.adjust_trackerName", trackerName)
        editor.putString("flutter.adjust_trackerToken", trackerToken)
        editor.putString("flutter.adjust_device_id", adjustDeviceId)
        val saved = editor.commit()
        
        if (methodChannel != null) {
            try {
                methodChannel!!.invokeMethod("adjustAttribution", mapOf(
                    "source" to source,
                    "campaign" to campaign,
                    "adgroup" to adgroup,
                    "creative" to creative,
                    "trackerName" to trackerName,
                    "trackerToken" to trackerToken,
                    "adjustDeviceId" to adjustDeviceId
                ))
                Log.d("AdjustAttribution", "✅ Method channel called successfully")
            } catch (e: Exception) {
                Log.e("AdjustAttribution", "❌ Error calling method channel: ${e.message}")
            }
        }
    }
}
