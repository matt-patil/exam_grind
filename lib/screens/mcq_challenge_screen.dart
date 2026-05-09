import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MCQChallengeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;
  final bool isActiveMission;

  const MCQChallengeScreen({
    super.key,
    this.initialConfig,
    this.isActiveMission = false,
  });

  @override
  State<MCQChallengeScreen> createState() => _MCQChallengeScreenState();
}

class _MCQChallengeScreenState extends State<MCQChallengeScreen> {
  late int _targetCorrectCount;
  int _currentCorrectCount = 0;
  List<Map<String, dynamic>> _allQuestions = [];
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  int? _selectedOptionIndex;
  bool _isAnswered = false;

  // Timer for active mission
  Timer? _timer;
  double _timerProgress = 1.0;
  final int _totalSeconds = 60; // 60 seconds for MCQ

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _targetCorrectCount = widget.initialConfig?['mcqCount'] ?? 5;
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final String exam = widget.initialConfig?['exam'] ?? 'JEE';
      final String className = widget.initialConfig?['class'] ?? '11th';
      final Map<String, dynamic>? chaptersConfig = widget.initialConfig?['chapters'];
      
      List<Map<String, dynamic>> loadedQuestions = [];

      if (chaptersConfig != null && chaptersConfig.isNotEmpty) {
        for (var entry in chaptersConfig.entries) {
          String subject = entry.key;
          // Normalize Math/Maths
          if (subject == 'Maths') subject = 'Math';
          
          // Both JEE and NEET 11th class share the same datasets for Physics and Chemistry
          String pathExam = exam;
          if (exam == 'NEET' && className == '11th' && (subject == 'Physics' || subject == 'Chemistry')) {
            pathExam = 'JEE';
          }
          
          final List<dynamic> chapters = entry.value is List ? entry.value : [];
          
          for (var chapter in chapters) {
            final String filePath = 'assets/MCQ datasets/$pathExam/$className/$subject/$chapter/conceptual.json';
            try {
              final String content = await rootBundle.loadString(filePath);
              final List<dynamic> data = jsonDecode(content);
              for (var item in data) {
                loadedQuestions.add(Map<String, dynamic>.from(item));
              }
            } catch (e) {
              debugPrint('Error loading file $filePath: $e');
            }
          }
        }
      }

      // Fallback for older config or 'Random'
      if (loadedQuestions.isEmpty) {
        final List<dynamic>? subjectsRaw = widget.initialConfig?['subjects'];
        final List<String> subjects = subjectsRaw != null ? List<String>.from(subjectsRaw) : ['Math'];
        
        // If it's a test or no chapters selected, try to load at least one available dataset
        String defaultPath = 'assets/MCQ datasets/JEE/11th/Math/Sets/conceptual.json';
        if (subjects.contains('Physics')) {
          defaultPath = 'assets/MCQ datasets/JEE/11th/Physics/Units and Dimensions/conceptual.json';
        } else if (subjects.contains('Chemistry')) {
          defaultPath = 'assets/MCQ datasets/JEE/11th/Chemistry/Mole Concept/conceptual.json';
        } else if (subjects.contains('Biology')) {
          defaultPath = 'assets/MCQ datasets/NEET/11th/Biology/The Living World/conceptual.json';
        } else if (subjects.contains('Math') || subjects.contains('Maths')) {
          defaultPath = 'assets/MCQ datasets/JEE/11th/Math/Sets/conceptual.json';
        }
        
        try {
          final String content = await rootBundle.loadString(defaultPath);
          final List<dynamic> data = jsonDecode(content);
          for (var item in data) {
            loadedQuestions.add(Map<String, dynamic>.from(item));
          }
        } catch (e) {
          debugPrint('Error loading default file: $e');
        }
      }

      if (mounted) {
        setState(() {
          _allQuestions = loadedQuestions;
          _isLoading = false;
          _nextQuestion();
        });
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _nextQuestion() {
    if (_allQuestions.isEmpty) {
      setState(() {
        _currentQuestion = null;
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _currentQuestion = _allQuestions[_random.nextInt(_allQuestions.length)];
      _selectedOptionIndex = null;
      _isAnswered = false;
      
      if (widget.isActiveMission) {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timerProgress = 1.0;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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

  void _checkAnswer(int index) {
    if (_isAnswered) return;

    final String correctAnswer = _currentQuestion?['answer'] ?? '';
    final String selectedAnswer = (_currentQuestion?['options'] as List)[index];
    bool correct = selectedAnswer == correctAnswer;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (correct) {
        _currentCorrectCount++;
        if (_currentCorrectCount >= _targetCorrectCount) {
          _timer?.cancel();
          Navigator.pop(context, true);
        } else {
          _nextQuestion();
        }
      } else {
        // Wrong answer, give another question
        _nextQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F11),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_currentQuestion == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F11),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No questions found for selection', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Bar
            if (widget.isActiveMission)
              Container(
                height: 4,
                width: double.infinity,
                color: Colors.grey[900],
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _timerProgress,
                  child: Container(color: const Color(0xFFBB86FC)),
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
                    '$_currentCorrectCount / $_targetCorrectCount',
                    style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.volume_off, color: Colors.grey, size: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    LatexText(
                      text: _currentQuestion!['question'],
                      fontSize: 18,
                    ),
                    const SizedBox(height: 40),

                    // Options
                    ...?((_currentQuestion!['options'] as List?)?.asMap().entries.map((entry) {
                      return _buildOption(entry.key);
                    })),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index) {
    final optionText = _currentQuestion!['options'][index];
    bool isSelected = _selectedOptionIndex == index;
    
    Color borderColor = Colors.grey[800]!;
    Color bgColor = const Color(0xFF1E1E1E);
    Widget? trailing;

    if (_isAnswered) {
      final String correctAnswer = _currentQuestion!['answer'] ?? '';
      bool isCorrectOption = optionText == correctAnswer;
      
      if (isCorrectOption) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        trailing = const Icon(Icons.check_circle, color: Colors.green);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        trailing = const Icon(Icons.cancel, color: Colors.red);
      }
    } else if (isSelected) {
      borderColor = const Color(0xFFBB86FC);
    }

    return GestureDetector(
      onTap: () => _checkAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Text(
              String.fromCharCode(65 + index), // A, B, C, D
              style: TextStyle(
                color: isSelected ? const Color(0xFFBB86FC) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LatexText(
                text: optionText,
                fontSize: 16,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

class LatexText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;

  const LatexText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // This regex looks for \( ... \) or $ ... $ or $$ ... $$
        // The dataset uses \\( and \\) (escaped in JSON)
        final List<InlineSpan> spans = [];
        final regex = RegExp(r'\\\(|\\\)|(?<!\\)\$|\$\$');
        
        int lastIndex = 0;
        bool isMath = false;
        
        final matches = regex.allMatches(text);
        
        if (matches.isEmpty) {
          return Text(
            text,
            style: TextStyle(color: color, fontSize: fontSize),
          );
        }

        for (final match in matches) {
          if (match.start > lastIndex) {
            final content = text.substring(lastIndex, match.start);
            if (isMath) {
              spans.add(WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Math.tex(
                      _cleanTex(content),
                      textStyle: TextStyle(color: color, fontSize: fontSize),
                      onErrorFallback: (err) => Text(
                        content,
                        style: TextStyle(color: Colors.red, fontSize: fontSize),
                      ),
                    ),
                  ),
                ),
              ));
            } else {
              spans.add(TextSpan(
                text: content,
                style: TextStyle(color: color, fontSize: fontSize),
              ));
            }
          }
          
          // Toggle isMath when we hit a delimiter
          final delimiter = match.group(0);
          if (delimiter == r'\(') {
            isMath = true;
          } else if (delimiter == r'\)') {
            isMath = false;
          } else {
            isMath = !isMath;
          }
          
          lastIndex = match.end;
        }

        if (lastIndex < text.length) {
          final remainingText = text.substring(lastIndex);
          spans.add(TextSpan(
            text: remainingText,
            style: TextStyle(color: color, fontSize: fontSize),
          ));
        }

        return RichText(
          text: TextSpan(children: spans),
        );
      }
    );
  }

  String _cleanTex(String tex) {
    // Dataset might have double backslashes which need to be single for flutter_math
    return tex.replaceAll(r'\\', r'\');
  }
}
