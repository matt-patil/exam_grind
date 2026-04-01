package com.example.exam_grind

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AlarmActivity : FlutterActivity() {
    private val CHANNEL = "com.example.exam_grind/alarm"
    private var initialAlarmId: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupAlarmDisplay()
        updateInitialAlarm(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        updateInitialAlarm(intent)
        val alarmId = intent.getStringExtra("alarm_id")
        if (alarmId != null && alarmId != "relaunch") {
            methodChannel?.invokeMethod("onAlarmRinging", alarmId)
        }
    }

    private fun updateInitialAlarm(intent: Intent) {
        val alarmId = intent.getStringExtra("alarm_id")
        if (alarmId != null && alarmId != "relaunch") {
            initialAlarmId = alarmId
        }
    }

    private fun setupAlarmDisplay() {
        // Show alarm screen even when device is locked
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            // Request keyguard dismissal (non-intrusive)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        // Keep screen on while alarm is active
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON)
    }

    override fun onBackPressed() {
        // Disable back button during alarm
        // super.onBackPressed() - commented out to prevent dismissal
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // If user tries to go Home, relaunch immediately to stay in front
        val relaunchIntent = Intent(this, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("alarm_id", "relaunch")
        }
        startActivity(relaunchIntent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<String>("id")
                    val timeInMillis = call.argument<Number>("timeInMillis")?.toLong()
                    val soundPath = call.argument<String>("soundPath")
                    val volume = call.argument<Double>("volume") ?: 0.8
                    if (id != null && timeInMillis != null && soundPath != null) {
                        NativeAlarmManager.scheduleAlarm(this@AlarmActivity, id, timeInMillis, soundPath, volume)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing arguments", null)
                    }
                }
                "cancelAlarm" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        NativeAlarmManager.cancelAlarm(this@AlarmActivity, id)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing id", null)
                    }
                }
                "stopAlarm" -> {
                    val stopIntent = Intent(this, AlarmService::class.java)
                    stopService(stopIntent)
                    result.success(true)
                    // Close this activity (back to home)
                    finish()
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
                "getInitialAlarm" -> {
                    result.success(initialAlarmId)
                    initialAlarmId = null
                }
                else -> result.notImplemented()
            }
        }
    }
}
