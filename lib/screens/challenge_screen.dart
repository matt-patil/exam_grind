import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/alarm_model.dart';

class ChallengeScreen extends StatefulWidget {
  final AlarmModel alarm;
  const ChallengeScreen({super.key, required this.alarm});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  int currentQuoteIndex = 0;
  final TextEditingController _textController = TextEditingController();
  String errorMessage = '';
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAlarmSound();
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.setAsset('assets/${widget.alarm.soundPath}');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _checkQuote() {
    // Check if the typed text matches the required quote exactly
    if (_textController.text.trim() == widget.alarm.motivationalQuotes[currentQuoteIndex].trim()) {
      setState(() {
        if (currentQuoteIndex < 2) {
          currentQuoteIndex++; // Move to next quote
          _textController.clear();
          errorMessage = '';
        } else {
          // Success! Alarm dismissed.
          _audioPlayer.stop(); // Stop the sound immediately
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alarm Dismissed! Great job!')),
          );
        }
      });
    } else {
      setState(() {
        errorMessage = 'Text does not match. Keep trying!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentQuote = widget.alarm.motivationalQuotes[currentQuoteIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary, // Red alert background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_on, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'WAKE UP!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      'Quote ${currentQuoteIndex + 1} of 3',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"$currentQuote"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type the quote here...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        errorText: errorMessage.isNotEmpty ? errorMessage : null,
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _checkQuote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
