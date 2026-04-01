import 'package:flutter/material.dart';

// Represents a single alarm in the app
class AlarmModel {
  final String id;
  TimeOfDay time;
  String name;
  bool isEnabled;
  bool isOneTime;
  List<bool> activeDays; // Represents [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
  List<String> motivationalQuotes; // The 3 quotes for the challenge
  String soundPath; // Path to the alarm sound file
  double volume; // Alarm volume (0.0 to 1.0)
  Map<String, dynamic>? mission; // Mission configuration

  AlarmModel({
    required this.id,
    required this.time,
    this.name = '',
    this.isEnabled = true,
    this.isOneTime = true,
    required this.activeDays,
    required this.motivationalQuotes,
    this.soundPath = 'sounds/alarm.mp3',
    this.volume = 0.8,
    this.mission,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'name': name,
      'isEnabled': isEnabled,
      'isOneTime': isOneTime,
      'activeDays': activeDays,
      'motivationalQuotes': motivationalQuotes,
      'soundPath': soundPath,
      'volume': volume,
      'mission': mission,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      name: json['name'],
      isEnabled: json['isEnabled'],
      isOneTime: json['isOneTime'],
      activeDays: List<bool>.from(json['activeDays']),
      motivationalQuotes: List<String>.from(json['motivationalQuotes']),
      soundPath: json['soundPath'],
      volume: (json['volume'] ?? 0.8).toDouble(),
      mission: json['mission'],
    );
  }
}
