import 'dart:async';
import 'package:flutter/material.dart';

class TypingMissionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;

  const TypingMissionScreen({super.key, this.initialConfig});

  @override
  State<TypingMissionScreen> createState() => _TypingMissionScreenState();
}

class _TypingMissionScreenState extends State<TypingMissionScreen> {
  List<String> _selectedPhrases = [];
  int _currentPhraseIndex = 0;
  final TextEditingController _typingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  Timer? _timer;
  double _timerProgress = 1.0;
  final int _totalSeconds = 60; // 60 seconds per phrase
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null && widget.initialConfig!['phrases'] != null) {
      _selectedPhrases = List<String>.from(widget.initialConfig!['phrases']);
    } else {
      // Fallback if empty
      _selectedPhrases = ["Every morning you have two choices. Continue to sleep with your dreams, or wake up and chase them."];
    }
    
    // Automatically focus the hidden text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerProgress = 1.0;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
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
      Navigator.pop(context, false); // Return false indicating failure
    }
  }

  void _onTextChanged(String text) {
    String target = _selectedPhrases[_currentPhraseIndex];
    setState(() {
      _isComplete = text == target;
    });
  }

  void _onCompletePressed() {
    if (!_isComplete) return;

    if (_currentPhraseIndex < _selectedPhrases.length - 1) {
      setState(() {
        _currentPhraseIndex++;
        _typingController.clear();
        _isComplete = false;
        _startTimer(); // Reset timer for next phrase
      });
    } else {
      // Mission fully successful
      _timer?.cancel();
      Navigator.pop(context, true); // Return true indicating success
    }
  }

  @override
  Widget build(BuildContext context) {
    String targetPhrase = _selectedPhrases.isNotEmpty 
        ? _selectedPhrases[_currentPhraseIndex] 
        : "";
    String currentInput = _typingController.text;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Bar (Thin yellow bar at top)
            Container(
              height: 3,
              width: double.infinity,
              color: Colors.grey[900],
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _timerProgress,
                child: Container(color: Colors.amber),
              ),
            ),

            // Header section (Back, Progress, Mute)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  Text(
                    '${_currentPhraseIndex + 1} / ${_selectedPhrases.length}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.volume_off, color: Colors.grey[400], size: 24),
                ],
              ),
            ),

            // Typing Area
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Stack(
                  children: [
                    // Invisible TextField to capture input and keep keyboard open
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _typingController,
                        focusNode: _focusNode,
                        maxLines: null,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: _onTextChanged,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    
                    // The visual text rendering
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Wrap(
                        spacing: 0, // No spacing between characters
                        runSpacing: 4, // Spacing between lines
                        children: _buildCharacterWidgets(targetPhrase, currentInput),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section: Character count and Complete button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentInput.length} / ${targetPhrase.length}',
                    style: const TextStyle(
                      color: Color(0xFF00D084), // A teal/cyan color similar to the image
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isComplete ? _onCompletePressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isComplete ? const Color(0xFF4A4A4C) : const Color(0xFF2C2C2E),
                        foregroundColor: _isComplete ? Colors.white : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFF2C2C2E),
                        disabledForegroundColor: Colors.grey[600],
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCharacterWidgets(String target, String input) {
    List<Widget> widgets = [];
    bool hasErrorOccurred = false;

    // Split target into words to keep words together on wrap
    List<String> targetWords = _splitIntoWordsWithSpaces(target);
    int charIndex = 0;

    for (String word in targetWords) {
      List<Widget> wordChars = [];
      for (int i = 0; i < word.length; i++) {
        String expectedChar = word[i];
        
        Color textColor;
        Color? bgColor;

        if (charIndex < input.length) {
          String inputChar = input[charIndex];
          if (inputChar == expectedChar && !hasErrorOccurred) {
            // Correct char
            textColor = Colors.white;
            bgColor = const Color(0xFF2C2C2E); // Dark grey background for typed text
          } else {
            // Incorrect char
            textColor = Colors.redAccent;
            bgColor = const Color(0xFF2C2C2E); // Keep dark grey bg even for wrong typed text
            hasErrorOccurred = true;
          }
        } else {
          // Untyped char
          textColor = Colors.grey[600]!;
          bgColor = Colors.transparent;
        }

        // The cursor indicator (blue teardrop in the image)
        bool isCursorPosition = charIndex == input.length;

        wordChars.add(
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                color: bgColor,
                child: Text(
                  expectedChar,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace', // To make character widths more uniform
                  ),
                ),
              ),
              if (isCursorPosition)
                Positioned(
                  left: 0,
                  bottom: -5, // Slightly below the character
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B6FFF), // Blue cursor color
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          )
        );
        charIndex++;
      }
      
      // Wrap the word so it doesn't break mid-word across lines
      widgets.add(Wrap(children: wordChars));
    }

    return widgets;
  }

  // Helper to split a string into words but keep the trailing spaces attached to the words
  List<String> _splitIntoWordsWithSpaces(String text) {
    List<String> result = [];
    String currentWord = "";
    for (int i = 0; i < text.length; i++) {
      currentWord += text[i];
      if (text[i] == ' ') {
        result.add(currentWord);
        currentWord = "";
      }
    }
    if (currentWord.isNotEmpty) {
      result.add(currentWord);
    }
    return result;
  }
}
