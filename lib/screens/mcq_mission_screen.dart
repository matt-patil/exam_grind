import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MCQMissionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;

  const MCQMissionScreen({
    super.key,
    this.initialConfig,
  });

  @override
  State<MCQMissionScreen> createState() => _MCQMissionScreenState();
}

class _MCQMissionScreenState extends State<MCQMissionScreen> {
  String? _selectedExam; // 'JEE' or 'NEET'
  final List<String> _selectedSubjects = [];
  late int _mcqCount;

  final List<String> _jeeSubjects = ['Maths', 'Physics', 'Chemistry', 'Random'];
  final List<String> _neetSubjects = ['Biology', 'Physics', 'Chemistry', 'Random'];

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.initialConfig?['exam'];
    if (widget.initialConfig?['subjects'] != null) {
      _selectedSubjects.addAll(List<String>.from(widget.initialConfig?['subjects']));
    }
    _mcqCount = widget.initialConfig?['mcqCount'] ?? 5;
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        if (subject == 'Random') {
          _selectedSubjects.remove(subject);
        } else {
          _selectedSubjects.remove(subject);
        }
      } else {
        if (subject == 'Random') {
          _selectedSubjects.clear();
          _selectedSubjects.add(subject);
        } else {
          _selectedSubjects.remove('Random');
          _selectedSubjects.add(subject);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MCQ Mission', style: TextStyle(fontSize: 16, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mission Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBB86FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MCQ Challenge',
                  style: TextStyle(
                    color: Color(0xFF0F0F11),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Exam Selection
              const Text(
                'Select Exam',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildExamButton('JEE'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildExamButton('NEET'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Subject Selection (if exam is selected)
              if (_selectedExam != null) ...[
                Text(
                  'Select Subjects for $_selectedExam',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: (_selectedExam == 'JEE' ? _jeeSubjects : _neetSubjects).map((subject) {
                    return _buildSubjectButton(subject);
                  }).toList(),
                ),
                const SizedBox(height: 30),
              ],

              // MCQ Count Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Number of Questions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(
                          textTheme: CupertinoTextThemeData(
                            pickerTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: _mcqCount - 1,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _mcqCount = index + 1;
                            });
                          },
                          children: List<Widget>.generate(
                            20,
                            (int index) => Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: _mcqCount == index + 1
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
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedExam != null && _selectedSubjects.isNotEmpty)
                      ? () {
                          Navigator.pop(context, {
                            'type': 'MCQ',
                            'exam': _selectedExam,
                            'subjects': _selectedSubjects,
                            'mcqCount': _mcqCount,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: (_selectedExam != null && _selectedSubjects.isNotEmpty)
                          ? const Color(0xFF0F0F11)
                          : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

  Widget _buildExamButton(String exam) {
    bool isSelected = _selectedExam == exam;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExam = exam;
          _selectedSubjects.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBB86FC) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFBB86FC) : Colors.grey[800]!,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          exam,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0F0F11) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectButton(String subject) {
    bool isSelected = _selectedSubjects.contains(subject);
    return GestureDetector(
      onTap: () => _toggleSubject(subject),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBB86FC).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFBB86FC) : Colors.grey[700]!,
            width: 1.5,
          ),
        ),
        child: Text(
          subject,
          style: TextStyle(
            color: isSelected ? const Color(0xFFBB86FC) : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
