package com.example.striktnanay

import android.app.Activity
import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.SystemClock
import android.app.PendingIntent.FLAG_UPDATE_CURRENT
import android.app.PendingIntent.FLAG_IMMUTABLE

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.striktnanay.app/focus_mode"
    private val RINGTONE_CHANNEL = "com.striktnanay.app/ringtone"
    private val REQ_PICK_RINGTONE = 1001
    private var ringtoneResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentApp" -> {
                    val packageName = getCurrentAppPackage()
                    result.success(packageName)
                }
                "checkUsageStatsPermission" -> {
                    val hasPermission = hasUsageStatsPermission()
                    result.success(hasPermission)
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRingtone" -> {
                    ringtoneResult = result
                    val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select alarm sound")
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                    intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                    // Preselect current default alarm if nothing stored
                    val def = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM)
                    if (def != null) {
                        intent.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, def)
                    }
                    startActivityForResult(intent, REQ_PICK_RINGTONE)
                }
                "scheduleAlarm" -> {
                    // args: id (int), timeMillis (long), uri (string)
                    val id = (call.argument<Int>("id") ?: 0)
                    val timeMillis = (call.argument<Long>("timeMillis") ?: 0L)
                    val uri = call.argument<String>("uri")
                    val scheduled = scheduleAlarm(id, timeMillis, uri)
                    result.success(scheduled)
                }
                "cancelAlarm" -> {
                    val id = (call.argument<Int>("id") ?: 0)
                    val cancelled = cancelAlarm(id)
                    result.success(cancelled)
                }
                "stopAlarmSound" -> {
                    try {
                        val svc = Intent(this, RingtonePlayerService::class.java).apply {
                            action = RingtonePlayerService.ACTION_STOP
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(svc) else startService(svc)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun buildAlarmIntent(id: Int, uri: String?): Intent {
        val intent = Intent(this, AlarmReceiver::class.java)
        intent.putExtra("uri", uri)
        intent.putExtra("alarm_id", id)
        return intent
    }

    private fun scheduleAlarm(id: Int, timeMillis: Long, uri: String?): Boolean {
        try {
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            val intent = buildAlarmIntent(id, uri)
            val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE else FLAG_UPDATE_CURRENT
            val pending = PendingIntent.getBroadcast(this, id, intent, flags)
            // Use RTC_WAKEUP to wake device and set exact alarm
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pending)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pending)
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun cancelAlarm(id: Int): Boolean {
        try {
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            val intent = buildAlarmIntent(id, null)
            val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE else FLAG_UPDATE_CURRENT
            val pending = PendingIntent.getBroadcast(this, id, intent, flags)
            alarmManager.cancel(pending)
            pending.cancel()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun getCurrentAppPackage(): String? {
        if (!hasUsageStatsPermission()) {
            return null
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            time - TimeUnit.MINUTES.toMillis(1),
            time
        )

        if (stats.isNullOrEmpty()) {
            return null
        }

        // Get the most recently used app
        var mostRecentUsage: UsageStats? = null
        for (usageStats in stats) {
            if (mostRecentUsage == null || usageStats.lastTimeUsed > mostRecentUsage.lastTimeUsed) {
                mostRecentUsage = usageStats
            }
        }

        return mostRecentUsage?.packageName
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_PICK_RINGTONE) {
            val res = ringtoneResult
            ringtoneResult = null
            if (res == null) return
            if (resultCode != Activity.RESULT_OK) {
                res.success(null)
                return
            }
            var uri: Uri? = if (Build.VERSION.SDK_INT >= 33) {
                data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            }
            // If user selected "Default", some OEMs return null for PICKED_URI.
            if (uri == null) {
                uri = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM)
                if (uri == null) {
                    uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                }
            }
            res.success(uri?.toString())
        }
    }
}
