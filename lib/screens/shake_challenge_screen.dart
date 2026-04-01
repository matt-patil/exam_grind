import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeChallengeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;
  final bool isActiveMission;

  const ShakeChallengeScreen({
    super.key,
    this.initialConfig,
    this.isActiveMission = false,
  });

  @override
  State<ShakeChallengeScreen> createState() => _ShakeChallengeScreenState();
}

class _ShakeChallengeScreenState extends State<ShakeChallengeScreen> {
  late double _intensity; 
  late int _targetShakes;
  int _currentShakes = 0;
  
  // Mission state
  StreamSubscription? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  static const double shakeThresholdBase = 15.0;

  // Timer for active mission
  Timer? _timer;
  double _timerProgress = 1.0;
  final int _totalSeconds = 30;

  @override
  void initState() {
    super.initState();
    _intensity = widget.initialConfig?['intensity']?.toDouble() ?? 50.0;
    _targetShakes = widget.initialConfig?['duration'] ?? 30; // Using duration as shake count target

    if (widget.isActiveMission) {
      _startMission();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
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
    if (Navigator.canPop(context)) {
      Navigator.pop(context, false);
    }
  }

  void _startMission() {
    // Intensity affects threshold: 0 intensity -> 12 threshold, 100 intensity -> 25 threshold
    double threshold = 12.0 + (_intensity / 100.0) * 13.0;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > threshold) {
        DateTime now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(milliseconds: 200)) {
          _lastShakeTime = now;
          setState(() {
            _currentShakes++;
            if (_currentShakes >= _targetShakes) {
              _accelerometerSubscription?.cancel();
              _timer?.cancel();
              Navigator.pop(context, true);
            }
          });
        }
      }
    });
  }

  String _getIntensityLabel() {
    if (_intensity < 25) return 'Gentle';
    if (_intensity < 50) return 'Moderate';
    if (_intensity < 75) return 'Intense';
    return 'Very Intense';
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
                    '$_currentShakes / $_targetShakes',
                    style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.volume_off, color: Colors.grey, size: 24),
                ],
              ),
            ),

            const Spacer(),

            // Shake Icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _currentShakes.toDouble()),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: sin(value * 2 * pi / 5) * 0.2,
                  child: Icon(
                    Icons.vibration,
                    color: const Color(0xFF00D084),
                    size: 120 + (value % 5 * 2),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            const Text(
              'SHAKE IT!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Intensity: ${_getIntensityLabel()}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const Spacer(flex: 2),

            // Progress text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: _currentShakes / _targetShakes,
                backgroundColor: Colors.grey[900],
                color: const Color(0xFF00D084),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 60),
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
        title: const Text('Shake', style: TextStyle(fontSize: 16, color: Colors.white)),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Example Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D084),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Shake Challenge',
                  style: TextStyle(
                    color: Color(0xFF0F0F11),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Shake Challenge Description
              Column(
                children: [
                  const Text(
                    'Shake your phone to dismiss',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Visual representation of shake
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.vibration,
                          color: const Color(0xFF00D084),
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Prepare your device',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Intensity Section
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
                          _getIntensityLabel(),
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
                                value: _intensity,
                                min: 0,
                                max: 100,
                                activeColor: Colors.white,
                                inactiveColor: Colors.grey[700],
                                onChanged: (value) {
                                  setState(() {
                                    _intensity = value;
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
                  const SizedBox(height: 25),

                  // Duration Section (repurposed for shake count)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Number of Shakes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  if (_targetShakes > 5) _targetShakes -= 5;
                                });
                              },
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '$_targetShakes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _targetShakes += 5;
                                });
                              },
                            ),
                          ],
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
                          'type': 'Shake',
                          'intensity': _intensity,
                          'duration': _targetShakes,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D084),
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
    );
  }
}
