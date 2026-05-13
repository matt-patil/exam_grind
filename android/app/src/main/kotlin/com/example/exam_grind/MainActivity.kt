package com.example.exam_grind

import android.content.Intent
import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.exam_grind/alarm"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        val id = call.argument<String>("id")
                        val timeInMillis = call.argument<Number>("timeInMillis")?.toLong()
                        val soundPath = call.argument<String>("soundPath")
                        val volume = call.argument<Double>("volume") ?: 0.8
                        if (id != null && timeInMillis != null && soundPath != null) {
                            NativeAlarmManager.scheduleAlarm(this, id, timeInMillis, soundPath, volume)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Missing arguments", null)
                        }
                    }
                    "cancelAlarm" -> {
                        val id = call.argument<String>("id")
                        if (id != null) {
                            NativeAlarmManager.cancelAlarm(this, id)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Missing id", null)
                        }
                    }
                    "getInitialAlarm" -> {
                        result.success(null)  // Main activity never has initial alarm
                    }
                    "stopAlarm" -> {
                        val stopIntent = Intent(this, AlarmService::class.java)
                        stopService(stopIntent)
                        result.success(true)
                    }
                    "muteAlarm" -> {
                        val muteIntent = Intent(this, AlarmService::class.java).apply {
                            action = AlarmService.ACTION_STOP_AUDIO
                        }
                        startService(muteIntent)
                        result.success(true)
                    }
                    "unmuteAlarm" -> {
                        val unmuteIntent = Intent(this, AlarmService::class.java).apply {
                            action = AlarmService.ACTION_START_AUDIO
                        }
                        startService(unmuteIntent)
                        result.success(true)
                    }
                    "setMediaVolume" -> {
                        val volume = call.argument<Double>("volume") ?: 0.5
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val targetVolume = (volume * maxVolume).toInt()
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
