import 'package:flutter/material.dart';
import '../services/user_prefs.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _name = 'User';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = UserPrefs();
    final name = await prefs.getUserName();
    if (!mounted) return;
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final body = _aboutText(_name);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Striktnanay',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Focus smarter. Build habits. Get things done.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              const Text('Key Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _bullet('Pomodoro timer with work/break cycles'),
              _bullet('Customizable default durations'),
              _bullet('Reliable end-of-session alarm on Android'),
              _bullet('Notification status while a session runs'),
              _bullet('Optional app whitelist for focus mode'),
              const SizedBox(height: 24),
              const Text('Contact & Credits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Built for students and anyone who wants to focus more effectively. '
                'Made with Flutter. Icons by Material Icons.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(text)),
          ],
        ),
      );

  String _aboutText(String name) {
    return 'Hi $name,\n\n'
        'Striktnanay helps you stay focused using the Pomodoro technique: short, intense focus sessions followed by mindful breaks. '
        'Pick your default durations, start a session, and let the app remind you when it\'s time to switch. On Android, a native alarm ensures your alert rings even if the app is not open.'
        '\n\nUse the Settings page to personalize your experience — set your name, choose an alarm sound (Android), and adjust work/break defaults to fit your rhythm.';
  }
}
