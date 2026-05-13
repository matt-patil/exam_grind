import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'emergency_escape_screen.dart';

class MathChallengeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;
  final bool isActiveMission;

  const MathChallengeScreen({
    super.key,
    this.initialConfig,
    this.isActiveMission = false,
  });

  @override
  State<MathChallengeScreen> createState() => _MathChallengeScreenState();
}

class _MathChallengeScreenState extends State<MathChallengeScreen> {
  late double _difficulty; // 0 = Easy, 1 = Normal, 2 = Hard, 3 = Very Hard
  late int _problemCount;
  String _problemText = '';
  int _correctAnswer = 0;
  String _userAnswer = '';
  int _currentProblemIndex = 1;
  bool _isWrongAnswer = false;

  final List<String> _difficultyLabels = ['Easy', 'Normal', 'Hard', 'Very Hard'];
  final Random _random = Random();

  // Timer for active mission
  Timer? _timer;
  double _timerProgress = 1.0;
  final int _totalSeconds = 30;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.initialConfig?['difficulty']?.toDouble() ?? 0.0;
    _problemCount = widget.initialConfig?['problemCount'] ?? 3;
    _generateProblem();

    if (widget.isActiveMission) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    // If timer runs out, mission fails
    if (Navigator.canPop(context)) {
      Navigator.pop(context, false);
    }
  }

  void _generateProblem() {
    setState(() {
      int difficulty = _difficulty.round();
      if (difficulty == 0) {
        // Easy: (2-digit) + (1-digit)
        int a = _random.nextInt(90) + 10;
        int b = _random.nextInt(9) + 1;
        _problemText = '$a + $b =';
        _correctAnswer = a + b;
      } else if (difficulty == 1) {
        // Normal: (2-digit) + (2-digit)
        int a = _random.nextInt(90) + 10;
        int b = _random.nextInt(90) + 10;
        _problemText = '$a + $b =';
        _correctAnswer = a + b;
      } else if (difficulty == 2) {
        // Hard: (2-digit) + (2-digit) + (2-digit)
        int a = _random.nextInt(90) + 10;
        int b = _random.nextInt(90) + 10;
        int c = _random.nextInt(90) + 10;
        _problemText = '$a + $b + $c =';
        _correctAnswer = a + b + c;
      } else {
        // Very Hard: (2-digit * 1-digit) + (2-digit)
        int a = _random.nextInt(90) + 10;
        int b = _random.nextInt(8) + 2;
        int c = _random.nextInt(90) + 10;
        _problemText = '($a × $b) + $c =';
        _correctAnswer = (a * b) + c;
      }
      _userAnswer = '';
    });
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'back') {
        if (_userAnswer.isNotEmpty) {
          _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
        }
      } else if (key == 'check') {
        _checkAnswer();
      } else {
        if (_userAnswer.length < 5) {
          _userAnswer += key;
        }
      }
    });
  }

  void _checkAnswer() {
    int? typedValue = int.tryParse(_userAnswer);
    if (typedValue == _correctAnswer) {
      if (_currentProblemIndex < _problemCount) {
        setState(() {
          _currentProblemIndex++;
          _generateProblem();
          if (widget.isActiveMission) {
            _startTimer(); // Reset timer for next problem
          }
        });
      } else {
        // All problems solved
        _timer?.cancel();
        Navigator.pop(context, true);
      }
    } else {
      // Wrong answer
      setState(() {
        _isWrongAnswer = true;
        _generateProblem(); // Show a new question (also resets _userAnswer)
      });
      
      // Reset the flash after 500ms
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isWrongAnswer = false;
          });
        }
      });
    }
  }

  String _getDifficultyLabel() {
    int index = _difficulty.round();
    return index < _difficultyLabels.length ? _difficultyLabels[index] : 'Easy';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActiveMission) {
      return _buildActiveMissionUI();
    }
    return _buildConfigUI();
  }

  Widget _buildActiveMissionUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Bar at the top
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
            
            // Header: Progress and Mute
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
                    '$_currentProblemIndex / $_problemCount',
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

            const Spacer(flex: 1),

            // Math Problem
            Text(
              _problemText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Answer Display
            Container(
              width: 250,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isWrongAnswer ? Colors.red : Colors.white, 
                  width: 2
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userAnswer,
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  if (_userAnswer.isEmpty)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.white,
                    ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Numeric Keypad
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildKeypadRow(['7', '8', '9']),
                  _buildKeypadRow(['4', '5', '6']),
                  _buildKeypadRow(['1', '2', '3']),
                  _buildKeypadRow(['back', '0', 'check']),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) => Expanded(child: _buildKey(key))).toList(),
    );
  }

  Widget _buildKey(String key) {
    Widget child;
    Color bgColor = const Color(0xFF1E1E1E);
    
    if (key == 'back') {
      child = const Icon(Icons.backspace_outlined, color: Colors.white);
      bgColor = const Color(0xFF2C2C2E);
    } else if (key == 'check') {
      child = const Icon(Icons.check, color: Colors.white);
      bgColor = Colors.redAccent;
    } else {
      child = Text(key, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold));
    }

    return GestureDetector(
      onTap: () => _onKeyPress(key),
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: child,
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
        title: const Text('Math', style: TextStyle(fontSize: 16, color: Colors.white)),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Example Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B6FFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Example',
                    style: TextStyle(
                      color: Color(0xFF0F0F11),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Math Problem Display
                Column(
                  children: [
                    Text(
                      _problemText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Difficulty Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDifficultyLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Easy',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _difficulty,
                                  min: 0,
                                  max: 3,
                                  divisions: 3,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.grey[700],
                                  onChanged: (value) {
                                    setState(() {
                                      _difficulty = value;
                                      _generateProblem();
                                    });
                                  },
                                ),
                              ),
                              const Text(
                                'Hard',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Problem Count Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Number of Problems',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: CupertinoTheme(
                              data: const CupertinoThemeData(
                                textTheme: CupertinoTextThemeData(
                                  pickerTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: _problemCount - 1,
                                ),
                                itemExtent: 50,
                                onSelectedItemChanged: (int index) {
                                  setState(() {
                                    _problemCount = index + 1;
                                  });
                                },
                                children: List<Widget>.generate(
                                  99,
                                  (int index) => Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: _problemCount == index + 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Preview and Complete Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Preview action
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Preview',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Complete action - save the mission configuration
                          Navigator.pop(context, {
                            'type': 'Math',
                            'difficulty': _difficulty.round(),
                            'difficultyLabel': _getDifficultyLabel(),
                            'problemCount': _problemCount,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
