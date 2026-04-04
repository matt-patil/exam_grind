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
  // Structure: { Subject: { ChapterName: Difficulty } }
  final Map<String, Map<String, String>> _selectedChapters = {};
  late int _mcqCount;

  final List<String> _jeeSubjects = ['Maths', 'Physics', 'Chemistry', 'Random'];
  final List<String> _neetSubjects = ['Biology', 'Physics', 'Chemistry', 'Random'];

  final Map<String, List<String>> _chapterLists = {
    'Physics': [
      'Units and Measurements',
      'Kinematics',
      'Laws of Motion',
      'Work, Energy and Power'
    ],
    'Chemistry': [
      'Some Basic Concepts of Chemistry',
      'Structure of Atom',
      'Classification of Elements and Periodicity in Properties',
      'Chemical Bonding and Molecular Structure'
    ],
    'Maths': [
      'Basic Concepts of Maths',
      'Trigonometry',
      'Sets'
    ],
    'Biology': [
      'The Living World',
      'Biological Classification',
      'Plant Kingdom',
      'Animal Kingdom'
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.initialConfig?['exam'];
    if (widget.initialConfig?['subjects'] != null) {
      _selectedSubjects.addAll(List<String>.from(widget.initialConfig?['subjects']));
    }
    if (widget.initialConfig?['chapters'] != null) {
      final chaptersMap = widget.initialConfig?['chapters'] as Map;
      chaptersMap.forEach((sub, configs) {
        if (configs is Map) {
          _selectedChapters[sub.toString()] = Map<String, String>.from(configs);
        } else if (configs is List) {
          // Backward compatibility for old list-based format
          final Map<String, String> newMap = {};
          for (var chap in configs) {
            newMap[chap.toString()] = 'Easy';
          }
          _selectedChapters[sub.toString()] = newMap;
        }
      });
    }
    _mcqCount = widget.initialConfig?['mcqCount'] ?? 5;
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
        _selectedChapters.remove(subject);
      } else {
        if (subject == 'Random') {
          _selectedSubjects.clear();
          _selectedChapters.clear();
          _selectedSubjects.add(subject);
        } else {
          _selectedSubjects.remove('Random');
          _selectedSubjects.add(subject);
          _selectedChapters[subject] = {}; // Initialize empty map
        }
      }
    });
  }

  void _showChapterSelector(String subject) {
    final chapters = _chapterLists[subject] ?? [];
    if (chapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chapters for $subject',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final isSelected = _selectedChapters[subject]?.containsKey(chapter) ?? false;
                        final difficulty = _selectedChapters[subject]?[chapter] ?? 'Easy';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFFBB86FC),
                                checkColor: const Color(0xFF0F0F11),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedChapters[subject]?[chapter] = 'Easy';
                                    } else {
                                      _selectedChapters[subject]?.remove(chapter);
                                    }
                                  });
                                  setModalState(() {});
                                },
                              ),
                              Expanded(
                                child: Text(
                                  chapter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                CupertinoSlidingSegmentedControl<String>(
                                  groupValue: difficulty,
                                  backgroundColor: const Color(0xFF2C2C2E),
                                  thumbColor: const Color(0xFFBB86FC),
                                  children: const {
                                    'Easy': Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('Easy', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    ),
                                    'Mid': Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('Mid', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    ),
                                  },
                                  onValueChanged: (String? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedChapters[subject]?[chapter] = value;
                                      });
                                      setModalState(() {});
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F0F11),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

              // Chapter Selection for each selected subject
              if (_selectedSubjects.isNotEmpty && !_selectedSubjects.contains('Random')) ...[
                const Text(
                  'Select Chapters & Difficulty',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._selectedSubjects.map((subject) => _buildChapterDropdown(subject)).toList(),
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
                  onPressed: _canSave()
                      ? () {
                          Navigator.pop(context, {
                            'type': 'MCQ',
                            'exam': _selectedExam,
                            'subjects': _selectedSubjects,
                            'chapters': _selectedChapters,
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
                      color: _canSave()
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

  bool _canSave() {
    if (_selectedExam == null || _selectedSubjects.isEmpty) return false;
    if (_selectedSubjects.contains('Random')) return true;
    
    for (var subject in _selectedSubjects) {
      if (_selectedChapters[subject] == null || _selectedChapters[subject]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Widget _buildExamButton(String exam) {
    bool isSelected = _selectedExam == exam;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExam = exam;
          _selectedSubjects.clear();
          _selectedChapters.clear();
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
          color: isSelected ? const Color(0xFFBB86FC).withValues(alpha: 0.2) : Colors.transparent,
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

  Widget _buildChapterDropdown(String subject) {
    final selectedCount = _selectedChapters[subject]?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showChapterSelector(subject),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedCount == 0 
                      ? 'Select Chapter for $subject'
                      : '$selectedCount chapters selected for $subject',
                  style: TextStyle(
                    color: selectedCount == 0 ? Colors.grey : Colors.white,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
