import 'dart:async';
import 'package:flutter/material.dart';
import 'phrase_selection_screen.dart';
import 'emergency_escape_screen.dart';

class TypingChallengeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;
  final bool isActiveMission;

  const TypingChallengeScreen({
    super.key,
    this.initialConfig,
    this.isActiveMission = false,
  });

  @override
  State<TypingChallengeScreen> createState() => _TypingChallengeScreenState();
}

class _TypingChallengeScreenState extends State<TypingChallengeScreen> {
  List<String> _selectedPhrases = [];
  
  // Mission state
  int _currentPhraseIndex = 0;
  final TextEditingController _typingController = TextEditingController();
  Timer? _timer;
  double _timerProgress = 1.0;
  final int _totalSeconds = 60; // Typing gets more time
  bool _isWrong = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null && widget.initialConfig!['phrases'] != null) {
      _selectedPhrases = List<String>.from(widget.initialConfig!['phrases']);
    }

    if (widget.isActiveMission && _selectedPhrases.isNotEmpty) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typingController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerProgress = 1.0;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        double decrease = 0.1 / _totalSeconds;
        _timerProgress -= decrease;
        if (_timerProgress <= 0) {
          _timerProgress = 0;
          timer.cancel();
          _onTimerExpired();
        }
      });
    });
  }

  void _onTimerExpired() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, false);
    }
  }

  void _checkTyping(String value) {
    String target = _selectedPhrases[_currentPhraseIndex];
    if (value == target) {
      if (_currentPhraseIndex < _selectedPhrases.length - 1) {
        setState(() {
          _currentPhraseIndex++;
          _typingController.clear();
          _isWrong = false;
          _startTimer(); // Reset timer for next phrase
        });
      } else {
        // Success
        _timer?.cancel();
        Navigator.pop(context, true);
      }
    } else {
      // Check if user is typing correctly so far
      if (!target.startsWith(value)) {
        setState(() {
          _isWrong = true;
        });
      } else {
        setState(() {
          _isWrong = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActiveMission) {
      return _buildActiveMissionUI();
    }
    return _buildConfigUI();
  }

  Widget _buildActiveMissionUI() {
    String targetPhrase = _selectedPhrases.isNotEmpty 
        ? _selectedPhrases[_currentPhraseIndex] 
        : "No phrases selected";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Bar
            Container(
              height: 4,
              width: double.infinity,
              color: Colors.grey[900],
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _timerProgress,
                child: Container(color: Colors.amber),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  Text(
                    '${_currentPhraseIndex + 1} / ${_selectedPhrases.length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emergency_share, color: Colors.redAccent, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyEscapeScreen()),
                      );
                      if (result == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Type the phrase exactly',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      targetPhrase,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _typingController,
                      autofocus: true,
                      maxLines: null,
                      style: TextStyle(
                        color: _isWrong ? Colors.redAccent : Colors.white,
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start typing here...',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: _isWrong ? Colors.redAccent : Colors.grey[800]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: _isWrong ? Colors.redAccent : const Color(0xFFFF5261)),
                        ),
                      ),
                      onChanged: _checkTyping,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Typing', style: TextStyle(fontSize: 16, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Example Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5261),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Typing Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Select Phrase Button
              ElevatedButton.icon(
                onPressed: () async {
                  final List<String>? result = await Navigator.push<List<String>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhraseSelectionScreen(
                        initialSelectedPhrases: _selectedPhrases,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedPhrases = result;
                    });
                  }
                },
                icon: const Icon(Icons.format_quote, color: Colors.white),
                label: const Text('Select phrases'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Color(0xFFFF5261), width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${_selectedPhrases.length} phrases selected',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const Spacer(),

              // Complete Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'type': 'Typing',
                    'phrases': _selectedPhrases,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    color: Color(0xFF0F0F11),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
