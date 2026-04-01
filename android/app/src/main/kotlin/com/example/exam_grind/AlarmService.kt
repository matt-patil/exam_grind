package com.example.exam_grind

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var currentAlarmId: String = ""
    private var currentSoundPath: String = ""
    private var currentVolume: Double = 0.8

    companion object {
        const val ACTION_STOP_AUDIO = "com.example.exam_grind.STOP_AUDIO"
        const val ACTION_START_AUDIO = "com.example.exam_grind.START_AUDIO"
        private const val TAG = "AlarmService"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        
        if (action == ACTION_STOP_AUDIO) {
            mediaPlayer?.pause()
            return START_STICKY
        }
        
        if (action == ACTION_START_AUDIO) {
            mediaPlayer?.start()
            return START_STICKY
        }

        currentAlarmId = intent?.getStringExtra("alarm_id") ?: ""
        currentSoundPath = intent?.getStringExtra("soundPath") ?: "sounds/alarm.mp3"
        currentVolume = intent?.getDoubleExtra("volume", 0.8) ?: 0.8

        Log.d(TAG, "Starting alarm service for ID: $currentAlarmId, sound: $currentSoundPath")

        // Acquire WakeLock to keep CPU running
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "ExamGrind::AlarmWakeLock"
            )
            wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes max
        }

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        requestAudioFocus()
        createNotificationChannel()

        // Launch AlarmActivity to show fullscreen alarm UI
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("alarm_id", currentAlarmId)
        }
        
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            currentAlarmId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "exam_grind_alarm_channel")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Exam Grind")
            .setContentText("Alarm is ringing!")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .build()

        startForeground(1, notification)

        if (mediaPlayer == null) {
            playSound(currentSoundPath, currentVolume)
        } else {
            mediaPlayer?.start()
        }
        
        // Explicitly start the activity too
        try {
            startActivity(fullScreenIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error launching AlarmActivity", e)
        }

        return START_STICKY
    }

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val playbackAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(playbackAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener { focusChange ->
                    if (focusChange == AudioManager.AUDIOFOCUS_LOSS || focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                        // Re-gain focus and keep playing if possible, or at least don't stop forever
                        // For an alarm, we usually want to be very persistent
                    }
                }
                .build()
            audioManager?.requestAudioFocus(focusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus({ }, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "exam_grind_alarm_channel",
                "Alarm Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setBypassDnd(true)
                description = "Used for alarm notifications"
                setSound(null, null) // We play our own sound
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun playSound(soundPath: String, volume: Double) {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                // Try multiple possible paths for Flutter assets
                val possiblePaths = arrayOf(
                    "flutter_assets/assets/$soundPath",
                    "assets/$soundPath",
                    soundPath
                )
                
                var success = false
                for (path in possiblePaths) {
                    try {
                        val descriptor: AssetFileDescriptor = applicationContext.assets.openFd(path)
                        setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                        success = true
                        Log.d(TAG, "Successfully opened asset: $path")
                        break
                    } catch (e: Exception) {
                        Log.w(TAG, "Could not open asset: $path")
                    }
                }

                if (!success) {
                    Log.e(TAG, "Failed to find alarm sound in assets: $soundPath")
                    // Fallback to a system notification sound or something?
                    // For now, let's just use the default alarm if it exists
                    try {
                        val descriptor = applicationContext.assets.openFd("flutter_assets/assets/sounds/alarm.mp3")
                        setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                    } catch (e: Exception) {
                        return
                    }
                }

                val playbackAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setAudioAttributes(playbackAttributes)
                setVolume(volume.toFloat(), volume.toFloat())
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in playSound", e)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "Task removed (app swiped). Restarting UI.")
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("alarm_id", currentAlarmId)
        }
        try {
            startActivity(fullScreenIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error relaunching AlarmActivity", e)
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "Destroying AlarmService")
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        }
        if (wakeLock?.isHeld == true) wakeLock?.release()
        super.onDestroy()
    }
}
