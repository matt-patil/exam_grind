import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../models/alarm_model.dart';
import '../services/native_alarm_service.dart';
import 'math_challenge_screen.dart';
import 'typing_challenge_screen.dart';
import 'shake_challenge_screen.dart';
import 'mcq_challenge_screen.dart';

class AlarmRingingScreen extends StatefulWidget {
  final AlarmModel alarm;
  final bool isTest;
  const AlarmRingingScreen({super.key, required this.alarm, this.isTest = false});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  late AudioPlayer _audioPlayer;
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (widget.isTest) {
      _playAlarmSound();
    }
    _timeStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.setAsset('assets/${widget.alarm.soundPath}');
      await _audioPlayer.setVolume(widget.alarm.volume);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startMission() async {
    // Always stop the Flutter player preview
    await _audioPlayer.stop();

    // For non-test alarms, Mute native audio but keep service alive (Volume Lock stays on)
    if (!widget.isTest) {
      await NativeAlarmService.muteAlarm();
    }

    if (!mounted) return;

    final mission = widget.alarm.mission;
    Widget missionScreen;

    if (mission == null || mission['type'] == 'Math') {
      missionScreen = MathChallengeScreen(
        initialConfig: mission,
        isActiveMission: true,
      );
    } else if (mission['type'] == 'Typing') {
      missionScreen = TypingChallengeScreen(
        initialConfig: mission,
        isActiveMission: true,
      );
    } else if (mission['type'] == 'Shake') {
      missionScreen = ShakeChallengeScreen(
        initialConfig: mission,
        isActiveMission: true,
      );
    } else if (mission['type'] == 'MCQ') {
      missionScreen = MCQChallengeScreen(
        initialConfig: mission,
        isActiveMission: true,
      );
    } else {
      // Fallback
      missionScreen = MathChallengeScreen(
        initialConfig: mission,
        isActiveMission: true,
      );
    }

    final bool? success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => missionScreen),
    );

    if (success == true) {
      // Mission completed successfully, kill the native service and dismiss
      if (!widget.isTest) {
        await NativeAlarmService.stopAlarm();
      }
      if (mounted) {
        Navigator.pop(context); // Back to Home
      }
    } else {
      // Mission failed/cancelled: Unmute native audio or restart test sound
      if (widget.isTest) {
        _playAlarmSound();
      } else {
        await NativeAlarmService.unmuteAlarm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F11),
        body: SafeArea(
          child: StreamBuilder<DateTime>(
            stream: _timeStream,
            initialData: DateTime.now(),
            builder: (context, snapshot) {
            final now = snapshot.data!;
            final timeStr = DateFormat('hh:mm').format(now);
            final amPm = DateFormat('a').format(now);
            final dateStr = DateFormat('EEE, MMM d').format(now);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date and Time Heading
                  Column(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            amPm,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.alarm.name.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          widget.alarm.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Start Mission Button
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _startMission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Start Mission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Dismiss after mission',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
