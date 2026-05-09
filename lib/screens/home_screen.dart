import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../models/alarm_model.dart';
import '../widgets/alarm_card.dart';
import '../services/native_alarm_service.dart';
import 'add_alarm_screen.dart';
import 'alarm_ringing_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<AlarmModel> alarms = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadAlarms();
    _checkAndroidVersion();
    
    NativeAlarmService.setAlarmHandler((alarmId) {
      _triggerAlarmById(alarmId);
    });
    
    // Check if launched from alarm
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialAlarmId = await NativeAlarmService.getInitialAlarm();
      if (initialAlarmId != null) {
        _triggerAlarmById(initialAlarmId);
      }
    });
  }

  Future<void> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 26) {
          final prefs = await SharedPreferences.getInstance();
          final hasSeenWarning = prefs.getBool('has_seen_version_warning') ?? false;

          if (!hasSeenWarning && mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: const Text('Old Android Version', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Your Android version is old. Some features of this app may not work perfectly. For the best experience, please use Android 8.0 or newer.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await prefs.setBool('has_seen_version_warning', true);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }
  }

  Future<void> _loadAlarms() async {
    _prefs = await SharedPreferences.getInstance();
    final alarmsJson = _prefs.getStringList('alarms') ?? [];
    setState(() {
      alarms = alarmsJson.map((a) => AlarmModel.fromJson(jsonDecode(a))).toList();
    });
    // Ensure all loaded alarms are synced with native service
    _syncNativeAlarms();
  }

  Future<void> _saveAlarms() async {
    final alarmsJson = alarms.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList('alarms', alarmsJson);
    _syncNativeAlarms();
  }

  DateTime? _getNextAlarmTime(AlarmModel alarm) {
    if (!alarm.isEnabled) return null;
    DateTime now = DateTime.now();

    if (alarm.isOneTime) {
      DateTime alarmDT = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);
      if (alarmDT.isBefore(now)) {
        alarmDT = alarmDT.add(const Duration(days: 1));
      }
      return alarmDT;
    } else {
      for (int i = 0; i < 7; i++) {
        int dayToCheck = (now.weekday + i) % 7;
        if (dayToCheck == 0) dayToCheck = 7;
        int alarmDayIndex = dayToCheck == 7 ? 0 : dayToCheck;
        
        if (alarm.activeDays[alarmDayIndex]) {
          DateTime alarmDT = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute).add(Duration(days: i));
          if (i == 0 && alarmDT.isBefore(now)) {
            continue; 
          }
          return alarmDT;
        }
      }
    }
    return null;
  }

  Future<void> _syncNativeAlarms() async {
    for (var alarm in alarms) {
      await NativeAlarmService.cancelAlarm(alarm.id);
      if (alarm.isEnabled) {
        final nextTime = _getNextAlarmTime(alarm);
        if (nextTime != null) {
          await NativeAlarmService.scheduleAlarm(alarm.id, nextTime, alarm.soundPath, alarm.volume);
        }
      }
    }
  }

  void _triggerAlarmById(String id) {
    if (alarms.isEmpty) return;
    
    // Check if we are already on the ringing screen
    if (id == "relaunch") {
      return; 
    }
    
    int index = alarms.indexWhere((a) => a.id == id);
    if (index == -1) index = 0; // Fallback
    
    final alarm = alarms[index];
    
    if (alarm.isOneTime) {
      setState(() {
        alarm.isEnabled = false;
        _saveAlarms();
      });
    }
    _triggerAlarm(alarm, isTest: false);
  }

  void _triggerAlarm(AlarmModel alarm, {required bool isTest}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(alarm: alarm, isTest: isTest),
      ),
    );
  }

  Widget _buildNextAlarmStatus() {
    DateTime now = DateTime.now();
    DateTime? nearestAlarmTime;

    for (var alarm in alarms) {
      final nextTime = _getNextAlarmTime(alarm);
      if (nextTime != null) {
        if (nearestAlarmTime == null || nextTime.isBefore(nearestAlarmTime)) {
          nearestAlarmTime = nextTime;
        }
      }
    }

    if (nearestAlarmTime == null) {
      return const Text(
        'No upcoming alarms',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    Duration diff = nearestAlarmTime.difference(now);
    int days = diff.inDays;
    int hours = diff.inHours % 24;
    int minutes = diff.inMinutes % 60;

    String timeStr = '';
    if (days > 0) timeStr += '$days day${days > 1 ? 's' : ''} ';
    if (hours > 0) timeStr += '$hours hr ';
    if (minutes > 0 || (days == 0 && hours == 0)) timeStr += '$minutes min';

    return Text(
      'Alarm rings in $timeStr',
      style: const TextStyle(color: Colors.grey, fontSize: 14),
    );
  }

  Widget _buildAlarmsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Upcoming alarms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildNextAlarmStatus(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      final editedAlarm = await Navigator.push<AlarmModel>(
                        context,
                        MaterialPageRoute(builder: (context) => AddAlarmScreen(alarm: alarms[index])),
                      );
                      if (editedAlarm != null) {
                        setState(() {
                          alarms[index] = editedAlarm;
                          _saveAlarms();
                        });
                      }
                    },
                    onLongPress: () {
                      _triggerAlarm(alarms[index], isTest: true);
                    },
                    child: AlarmCard(
                      alarm: alarms[index],
                      onToggle: (val) {
                        setState(() {
                          alarms[index].isEnabled = val;
                          _saveAlarms();
                        });
                      },
                      onDelete: () async {
                        final alarmId = alarms[index].id;
                        await NativeAlarmService.cancelAlarm(alarmId);
                        setState(() {
                          alarms.removeAt(index);
                        });
                        await _saveAlarms();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _buildAlarmsTab() : const SettingsScreen(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final newAlarm = await Navigator.push<AlarmModel>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAlarmScreen()),
                );
                if (newAlarm != null) {
                  setState(() {
                    alarms.add(newAlarm);
                    _saveAlarms();
                  });
                }
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarm'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
