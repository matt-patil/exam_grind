import 'package:flutter/material.dart';
import 'math_challenge_screen.dart';
import 'typing_challenge_screen.dart';
import 'shake_challenge_screen.dart';
import 'mcq_mission_screen.dart';

class MissionSelectionModal extends StatelessWidget {
  final Map<String, dynamic>? initialConfig;
  const MissionSelectionModal({super.key, this.initialConfig});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Select a Mission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Mission Cards
              _MissionCard(
                title: 'Math',
                icon: Icons.calculate,
                color: const Color(0xFF5B6FFF),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MathChallengeScreen(
                        initialConfig: initialConfig?['type'] == 'Math' ? initialConfig : null,
                      ),
                    ),
                  );
                  if (context.mounted && result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const SizedBox(height: 16),

              _MissionCard(
                title: 'Typing',
                icon: Icons.keyboard,
                color: const Color(0xFFFF5261),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TypingChallengeScreen(
                        initialConfig: initialConfig?['type'] == 'Typing' ? initialConfig : null,
                      ),
                    ),
                  );
                  if (context.mounted && result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const SizedBox(height: 16),

              _MissionCard(
                title: 'Shake',
                icon: Icons.vibration,
                color: const Color(0xFF00D084),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShakeChallengeScreen(
                        initialConfig: initialConfig?['type'] == 'Shake' ? initialConfig : null,
                      ),
                    ),
                  );
                  if (context.mounted && result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const SizedBox(height: 16),

              _MissionCard(
                title: 'MCQ',
                icon: Icons.quiz,
                color: const Color(0xFFBB86FC),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MCQMissionScreen(
                        initialConfig: initialConfig?['type'] == 'MCQ' ? initialConfig : null,
                      ),
                    ),
                  );
                  if (context.mounted && result != null) {
                    Navigator.pop(context, result);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MissionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
