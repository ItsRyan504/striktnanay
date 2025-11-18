package com.example.striktnanay

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.Ringtone
import android.os.PowerManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class RingtonePlayerService : Service() {
    private var player: MediaPlayer? = null
    private var ringtone: Ringtone? = null
    private var wakeLock: PowerManager.WakeLock? = null
        private var isInForeground: Boolean = false

    companion object {
        const val CHANNEL_ID = "pomodoro_native_alarm"
        const val NOTIF_ID = 10001
        const val ACTION_PLAY = "com.striktnanay.action.PLAY"
        const val ACTION_STOP = "com.striktnanay.action.STOP"
        const val EXTRA_URI = "uri"
        const val EXTRA_ALARM_ID = "alarm_id"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            ACTION_PLAY -> {
                val uriStr = intent.getStringExtra(EXTRA_URI)
                startForegroundWithNotification(uriStr)
                startPlaying(uriStr)
            }
                ACTION_STOP -> {
                    stopPlaying()
                    try {
                        if (isInForeground) {
                            stopForeground(true)
                            isInForeground = false
                        }
                    } catch (_: Exception) {}
                    stopSelf()
                }
            else -> {
                // If service started without explicit action, treat as play with extras
                val uriStr = intent?.getStringExtra(EXTRA_URI)
                startForegroundWithNotification(uriStr)
                startPlaying(uriStr)
            }
        }
        return START_STICKY
    }

    private fun startForegroundWithNotification(uriStr: String?) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Alarm", NotificationManager.IMPORTANCE_HIGH)
            channel.setSound(null, null) // play sound via MediaPlayer, not notification
            nm.createNotificationChannel(channel)
        }

        val activityIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, 0, activityIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val stopIntent = Intent(this, RingtonePlayerService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this, 1, stopIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val notif: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Pomodoro")
            .setContentText("Time's up")
            .setSmallIcon(getNotificationIcon())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPending)
            .build()

        startForeground(NOTIF_ID, notif)
            isInForeground = true
    }

    private fun getNotificationIcon(): Int {
        val res = resources
        val id = res.getIdentifier("ic_notification", "mipmap", packageName)
        return if (id != 0) id else R.mipmap.ic_launcher
    }

    private fun startPlaying(uriStr: String?) {
        stopPlaying()
        try {
            // Acquire a partial wakelock so playback starts reliably when device wakes for alarm
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (wakeLock == null || !(wakeLock?.isHeld ?: false)) {
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "StriktNanay:AlarmWakelock").apply {
                    setReferenceCounted(false)
                    acquire(60_000) // hold up to 60s, auto-release safeguard
                }
            }
            val uri = if (!uriStr.isNullOrEmpty()) Uri.parse(uriStr) else RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                setDataSource(this@RingtonePlayerService, uri)
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback to system Ringtone if MediaPlayer fails (permissions / OEM quirk)
            try {
                val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ringtone = RingtoneManager.getRingtone(this, fallbackUri)
                ringtone?.play()
            } catch (ignored: Exception) {
            }
        }
    }

    private fun stopPlaying() {
        try {
            player?.stop()
            player?.release()
        } catch (e: Exception) {
            // ignore
        }
        player = null
        try { ringtone?.stop() } catch (_: Exception) {}
        ringtone = null
        if (wakeLock?.isHeld == true) {
            try { wakeLock?.release() } catch (_: Exception) {}
        }
        wakeLock = null
    }

    override fun onDestroy() {
        stopPlaying()
            isInForeground = false
        super.onDestroy()
    }
}
