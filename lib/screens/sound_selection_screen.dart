import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SoundSelectionScreen extends StatefulWidget {
  final String currentSound;
  const SoundSelectionScreen({super.key, required this.currentSound});

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> {
  late AudioPlayer _audioPlayer;
  late String _selectedSound;

  // Actual sound files from your assets/sounds/ folder
  final List<Map<String, String>> _availableSounds = [
    {'name': 'Default Alarm', 'path': 'sounds/alarm.mp3'},
    {'name': 'Asteroid', 'path': 'sounds/ACH_Asteroid.ogg'},
    {'name': 'Atomic Bell', 'path': 'sounds/ACH_Atomic_Bell.ogg'},
    {'name': 'Beep Once', 'path': 'sounds/ACH_Beep_Once.ogg'},
    {'name': 'Beep-Beep', 'path': 'sounds/ACH_Beep-Beep.ogg'},
    {'name': 'Chime Time', 'path': 'sounds/ACH_Chime_Time.ogg'},
    {'name': 'Comet', 'path': 'sounds/ACH_Comet.ogg'},
    {'name': 'Cosmos', 'path': 'sounds/ACH_Cosmos.ogg'},
    {'name': 'Finding Galaxy', 'path': 'sounds/ACH_Finding_Galaxy.ogg'},
    {'name': 'Galaxy Bells', 'path': 'sounds/ACH_Galaxy_Bells.ogg'},
    {'name': 'Homecoming', 'path': 'sounds/ACH_Homecoming.ogg'},
    {'name': 'Moon Discovery', 'path': 'sounds/ACH_Moon_Discovery.ogg'},
    {'name': 'Neptune', 'path': 'sounds/ACH_Neptune.ogg'},
    {'name': 'Orbit', 'path': 'sounds/ACH_Orbit.ogg'},
    {'name': 'Outer Bell', 'path': 'sounds/ACH_Outer_Bell.ogg'},
    {'name': 'Over the Horizon (2022)', 'path': 'sounds/ACH_Over_the_Horizon_2022_produced_by_SUGA_of_BTS.ogg'},
    {'name': 'Over the Horizon (SUGA)', 'path': 'sounds/ACH_Over_the_Horizon_by_SUGA_of_BTS.ogg'},
    {'name': 'Over the Horizon', 'path': 'sounds/ACH_Over_the_Horizon.ogg'},
    {'name': 'Planet', 'path': 'sounds/ACH_Planet.ogg'},
    {'name': 'Pluto', 'path': 'sounds/ACH_Pluto.ogg'},
    {'name': 'Polaris', 'path': 'sounds/ACH_Polaris.ogg'},
    {'name': 'Puddles', 'path': 'sounds/ACH_Puddles.ogg'},
    {'name': 'Quantum Bell', 'path': 'sounds/ACH_Quantum_Bell.ogg'},
    {'name': 'Satellite', 'path': 'sounds/ACH_Satellite.ogg'},
    {'name': 'Shooting Star', 'path': 'sounds/ACH_Shooting_Star.ogg'},
    {'name': 'Sky High', 'path': 'sounds/ACH_Sky_High.ogg'},
    {'name': 'Space Bell', 'path': 'sounds/ACH_Space_Bell.ogg'},
    {'name': 'Sunlight', 'path': 'sounds/ACH_Sunlight.ogg'},
    {'name': 'Synth Bell', 'path': 'sounds/ACH_Synth_Bell.ogg'},
    {'name': 'Universe Bell', 'path': 'sounds/ACH_Universe_Bell.ogg'},
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _selectedSound = widget.currentSound;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset('assets/$path');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        title: const Text('Select Alarm Sound'),
        actions: [
          TextButton(
            onPressed: () async {
              await _audioPlayer.stop();
              if (mounted) {
                Navigator.pop(context, _selectedSound);
              }
            },
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _availableSounds.length,
        itemBuilder: (context, index) {
          final sound = _availableSounds[index];
          final isSelected = _selectedSound == sound['path'];

          return ListTile(
            title: Text(
              sound['name']!,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
            onTap: () {
              setState(() {
                _selectedSound = sound['path']!;
              });
              _playSound(sound['path']!);
            },
          );
        },
      ),
    );
  }
}
