import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Format the time for display
    final String hour = alarm.time.hourOfPeriod == 0 ? '12' : alarm.time.hourOfPeriod.toString();
    final String minute = alarm.time.minute.toString().padLeft(2, '0');
    final String amPm = alarm.time.period == DayPeriod.am ? 'am' : 'pm';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Dark grey card color
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alarm Name in Bold at the top
                Text(
                  alarm.name.isNotEmpty ? alarm.name : 'Alarm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Show "One-time" or the active days
                Text(
                  alarm.isOneTime ? 'One-time' : _getDaysString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$hour:$minute ',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: alarm.isEnabled ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    Text(
                      amPm,
                      style: TextStyle(
                        fontSize: 20,
                        color: alarm.isEnabled ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.label_important_outline, // The small tag icon
                      size: 16,
                      color: alarm.isEnabled ? Colors.grey : Colors.grey[800],
                    )
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The active/inactive toggle switch
              Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[800],
              ),
              const SizedBox(height: 10),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: const Color(0xFF2C2C2E),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // Helper method to format the S M T W T F S string
  String _getDaysString() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    String result = '';
    for (int i = 0; i < alarm.activeDays.length; i++) {
      if (alarm.activeDays[i]) {
        result += '${days[i]} ';
      }
    }
    return result.trim();
  }
}