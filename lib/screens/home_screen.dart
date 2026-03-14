import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../widgets/alarm_card.dart';
import 'add_alarm_screen.dart';
import 'alarm_ringing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  String? _lastTriggeredMinute; // To prevent multiple triggers in same minute
  List<AlarmModel> alarms = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    // Start the timer to check every 10 seconds (more efficient than every second)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAlarms();
    });
  }

  Future<void> _loadAlarms() async {
    _prefs = await SharedPreferences.getInstance();
    final alarmsJson = _prefs.getStringList('alarms') ?? [];
    setState(() {
      alarms = alarmsJson.map((a) => AlarmModel.fromJson(jsonDecode(a))).toList();
    });
  }

  Future<void> _saveAlarms() async {
    final alarmsJson = alarms.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList('alarms', alarmsJson);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentMinuteString = '${now.hour}:${now.minute}';

    if (_lastTriggeredMinute == currentMinuteString) return;

    for (var alarm in alarms) {
      if (alarm.isEnabled && 
          alarm.time.hour == currentTime.hour && 
          alarm.time.minute == currentTime.minute) {
        
        // Check if it's the right day for recurring alarms
        bool shouldTrigger = false;
        if (alarm.isOneTime) {
          shouldTrigger = true;
          // Disable one-time alarm after it triggers
          setState(() {
            alarm.isEnabled = false;
            _saveAlarms();
          });
        } else {
          // DateTime.weekday: 1 = Mon, ..., 7 = Sun
          // activeDays: 0 = Sun, 1 = Mon, ...
          int dayIndex = now.weekday == 7 ? 0 : now.weekday;
          if (alarm.activeDays[dayIndex]) {
            shouldTrigger = true;
          }
        }

        if (shouldTrigger) {
          _lastTriggeredMinute = currentMinuteString;
          _triggerAlarm(alarm);
          break; // Only trigger one alarm at a time
        }
      }
    }
  }

  void _triggerAlarm(AlarmModel alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmRingingScreen(alarm: alarm),
      ),
    );
  }

  Widget _buildNextAlarmStatus() {
    DateTime now = DateTime.now();
    DateTime? nearestAlarmTime;

    for (var alarm in alarms) {
      if (!alarm.isEnabled) continue;

      if (alarm.isOneTime) {
        DateTime alarmDT = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);
        if (alarmDT.isBefore(now)) {
          alarmDT = alarmDT.add(const Duration(days: 1));
        }
        if (nearestAlarmTime == null || alarmDT.isBefore(nearestAlarmTime)) {
          nearestAlarmTime = alarmDT;
        }
      } else {
        // Find the next active day
        for (int i = 0; i < 7; i++) {
          int dayToCheck = (now.weekday + i) % 7;
          if (dayToCheck == 0) dayToCheck = 7; // DateTime uses 1-7 (Mon-Sun)
          
          int alarmDayIndex = dayToCheck == 7 ? 0 : dayToCheck; // activeDays uses 0-6 (Sun-Sat)
          
          if (alarm.activeDays[alarmDayIndex]) {
            DateTime alarmDT = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute).add(Duration(days: i));
            
            // If it's today but the time has already passed
            if (i == 0 && alarmDT.isBefore(now)) {
              // Find the next scheduled day after today
              continue; 
            }
            
            if (nearestAlarmTime == null || alarmDT.isBefore(nearestAlarmTime)) {
              nearestAlarmTime = alarmDT;
            }
            break; // Found earliest for this specific recurring alarm
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Upcoming alarms', // Or 'No upcoming alarms' based on list
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildNextAlarmStatus(),
              const SizedBox(height: 20),
              // List of Alarms
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
                      // FOR TESTING: Long press an alarm to simulate it ringing!
                      onLongPress: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlarmRingingScreen(alarm: alarms[index]),
                          ),
                        );
                      },
                      child: AlarmCard(
                        alarm: alarms[index],
                        onToggle: (val) {
                          setState(() {
                            alarms[index].isEnabled = val;
                            _saveAlarms();
                          });
                        },
                        onDelete: () {
                          setState(() {
                            alarms.removeAt(index);
                            _saveAlarms();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // The Floating Action Button for adding new alarms
      floatingActionButton: FloatingActionButton(
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
      ),
      // Bottom Navigation Bar keeping only the un-crossed sections
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarm'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Report'),
        ],
      ),
    );
  }
}
