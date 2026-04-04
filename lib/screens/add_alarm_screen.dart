import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import '../models/alarm_model.dart';
import 'sound_selection_screen.dart';
import 'mission_selection_modal.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key, this.alarm});

  final AlarmModel? alarm;

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late TimeOfDay selectedTime;
  late String alarmName;
  late bool isOneTime;
  late List<bool> activeDays;
  late String selectedSoundPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _volume = 0.8;
  Map<String, dynamic>? selectedMission;
  
  // Controllers
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    if (widget.alarm != null) {
      selectedTime = widget.alarm!.time;
      alarmName = widget.alarm!.name;
      isOneTime = widget.alarm!.isOneTime;
      activeDays = List.from(widget.alarm!.activeDays);
      selectedSoundPath = widget.alarm!.soundPath;
      _volume = widget.alarm!.volume;
      selectedMission = widget.alarm!.mission;
    } else {
      selectedTime = TimeOfDay.now();
      alarmName = '';
      isOneTime = true;
      activeDays = List.filled(7, false);
      selectedSoundPath = 'sounds/alarm.mp3';
    }
    _nameController = TextEditingController(text: alarmName);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _playVolumePreview() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setAsset('assets/$selectedSoundPath');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing volume preview: $e');
    }
  }

  String getRingInText() {
    DateTime now = DateTime.now();
    DateTime alarmTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    Duration diff = alarmTime.difference(now);
    int hours = diff.inHours;
    int minutes = diff.inMinutes % 60;
    return 'Ring in $hours hr $minutes min';
  }

  String _getMissionSummary() {
    if (selectedMission == null) return 'No mission selected';
    final type = selectedMission!['type'] ?? 'Mission';
    if (type == 'Math') {
      final difficulty = selectedMission!['difficultyLabel'] ?? 'Easy';
      final count = selectedMission!['problemCount'] ?? 3;
      return 'Math ($difficulty, $count problems)';
    }
    return type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.alarm == null ? 'Wake-up alarm' : 'Edit alarm', style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Alarm Name TextField
          TextField(
            controller: _nameController,
            onChanged: (val) => alarmName = val,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              icon: Icon(Icons.wb_sunny, color: Colors.amber),
              hintText: 'Please fill in the alarm name',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.edit, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          
          // Cupertino Time Picker - Increased height and font size
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 32),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2020, 1, 1, selectedTime.hour, selectedTime.minute),
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    selectedTime = TimeOfDay(hour: newTime.hour, minute: newTime.minute);
                  });
                },
              ),
            ),
          ),
          
          Center(
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: Text(getRingInText(), style: const TextStyle(color: Colors.grey)),
             )
          ),

          // Repeat Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('One-time', style: TextStyle(color: Colors.grey)),
              Row(
                children: [
                  Checkbox(
                    value: !isOneTime && activeDays.every((day) => day),
                    onChanged: (val) {
                      setState(() {
                        bool isDaily = val ?? false;
                        if (isDaily) {
                          isOneTime = false;
                          activeDays = List.filled(7, true);
                        } else {
                          isOneTime = true;
                          activeDays = List.filled(7, false);
                        }
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Text('Daily', style: TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          
          // Days of the week bubbles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    activeDays[index] = !activeDays[index];
                    isOneTime = !activeDays.contains(true);
                  });
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: activeDays[index] 
                      ? Theme.of(context).colorScheme.primary 
                      : const Color(0xFF2C2C2E),
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: activeDays[index] ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 30),
          
          // --- MISSION SECTION ---
          const Text('Mission', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                builder: (context) => MissionSelectionModal(initialConfig: selectedMission),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                backgroundColor: const Color(0xFF1E1E1E),
                isScrollControlled: true,
              );
              if (result != null) {
                setState(() {
                  selectedMission = result;
                });
              }
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: selectedMission == null 
                ? Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedMission!['type'] == 'Math' ? Icons.calculate : Icons.extension,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedMission!['type'] ?? 'Mission',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getMissionSummary(),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Alarm Sound Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alarm sound', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.access_alarm, 
                    color: Colors.white, 
                    size: 30
                  ),
                  const SizedBox(width: 15),
                  // Clickable area for changing the sound
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        if (mounted) {
                          final String? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SoundSelectionScreen(currentSound: selectedSoundPath),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              selectedSoundPath = result;
                            });
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedSoundPath.split('/').last
                              .replaceAll('.mp3', '')
                              .replaceAll('.ogg', '')
                              .replaceAll('ACH_', '')
                              .replaceAll('_', ' '), 
                            style: const TextStyle(color: Colors.white, fontSize: 16)
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.grey, size: 28),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (val) {
                        setState(() {
                          _volume = val;
                        });
                        _audioPlayer.setVolume(val);
                      },
                      onChangeEnd: (val) {
                        _playVolumePreview();
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey[800],
                    ),
                  ),
                  const Icon(Icons.vibration, color: Colors.grey, size: 18),
                ],
              )
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
      // Save Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: () {
              _audioPlayer.stop();
              if (mounted) {
                // Create new alarm object and pass it back
                final newAlarm = AlarmModel(
                  id: widget.alarm?.id ?? DateTime.now().toString(),
                  time: selectedTime,
                  name: alarmName,
                  isOneTime: isOneTime,
                  activeDays: activeDays,
                  motivationalQuotes: [
                    "I am ready to conquer the day",
                    "Every morning is a new opportunity",
                    "Discipline equals freedom",
                  ],
                  soundPath: selectedSoundPath,
                  volume: _volume,
                  mission: selectedMission,
                );
                Navigator.pop(context, newAlarm);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
