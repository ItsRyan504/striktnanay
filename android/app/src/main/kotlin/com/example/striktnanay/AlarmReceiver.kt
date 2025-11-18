package com.example.striktnanay

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val uri = intent.getStringExtra("uri")
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val playIntent = Intent(context, RingtonePlayerService::class.java).apply {
            this.action = RingtonePlayerService.ACTION_PLAY
            putExtra(RingtonePlayerService.EXTRA_URI, uri)
            putExtra(RingtonePlayerService.EXTRA_ALARM_ID, alarmId)
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(playIntent)
        } else {
            context.startService(playIntent)
        }
    }
}
