import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  // Ensure Flutter bindings are initialized before calling SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChallengeAlarmApp());
}

class ChallengeAlarmApp extends StatelessWidget {
  const ChallengeAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Challenge Alarm',
      debugShowCheckedModeBanner: false,
      // Global dark theme configuration to match the screenshots
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F11), // Deep black/grey
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F11),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5261), // The pinkish/red accent color
          surface: Color(0xFF1E1E1E), // Card backgrounds
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
