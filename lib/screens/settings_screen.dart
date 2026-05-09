import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showTroubleshootingInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Alarm Troubleshooting', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'If your alarms are not ringing or not showing up on the screen, please check these two settings:\n\n'
            'A. Disable Battery Restrictions\n'
            '1. Go to your phone\'s Settings.\n'
            '2. Tap on Apps.\n'
            '3. Select Exam Grind.\n'
            '4. Tap Battery.\n'
            '5. Choose Unrestricted.\n\n'
            'B. Enable "Appear on top"\n'
            '1. Go to your phone\'s Settings.\n'
            '2. Tap on Apps.\n'
            '3. Select Exam Grind.\n'
            '4. Look for "Appear on top" or "Display over other apps".\n'
            '5. Turn the switch ON.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchFeedbackForm() async {
    final Uri url = Uri.parse(
        'https://docs.google.com/forms/d/e/1FAIpQLScYkGgQUmkGfkqTDaYopIe21R4a_kbwMaGg1OkemmHHy1W4SQ/viewform?usp=publish-editor');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            
            // Troubleshooting Section
            GestureDetector(
              onTap: () => _showTroubleshootingInstructions(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5261)),
                        SizedBox(width: 12),
                        Text(
                          'Alarm not Working?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'If your alarms are delayed or not showing up on screen when the phone is locked, tap here to see how to fix it by tweaking Android settings.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tap for more',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5B6FFF), fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF5B6FFF)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Feedback Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bug_report, color: Color(0xFF5B6FFF)),
                      SizedBox(width: 12),
                      Text(
                        'Feedback & Bug Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Found a bug or have a suggestion? Let us know so we can improve your exam prep experience.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchFeedbackForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3A3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Send Feedback / Bug Report'),
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
}
