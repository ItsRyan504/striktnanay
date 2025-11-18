package com.example.striktnanay

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        try {
            // Flutter shared preferences live in "FlutterSharedPreferences" with key prefix "flutter."
            val sp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isRunning = sp.getBoolean("flutter.timer_is_running", false)
            val targetEpoch = sp.getLong("flutter.timer_target_epoch_ms", 0L)
            val phase = sp.getString("flutter.timer_phase", "work") ?: "work"

            if (!isRunning) return
            val now = System.currentTimeMillis()
            if (targetEpoch <= now) return

            // Pick consistent alarm id by phase to match existing flow
            val id = if (phase == "work") 100 else 101

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val playIntent = Intent(context, AlarmReceiver::class.java).apply {
                // AlarmReceiver will start foreground playback service
                putExtra("uri", null as String?)
                putExtra("alarm_id", id)
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
            val pending = PendingIntent.getBroadcast(context, id, playIntent, flags)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetEpoch, pending)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, targetEpoch, pending)
            }
        } catch (_: Exception) {
            // Ignore — best-effort reschedule
        }
    }
}
