import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/user_prefs.dart';
// Removed ringtone & notification prefs imports (alarm sound disabled)
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = 'User';
  int _work = 25;
  int _break = 5;
  bool _autoContinue = true;
  bool _loading = true;
  VoidCallback? _autoContinueListener;

  @override
  void initState() {
    super.initState();
    _autoContinueListener = () {
      final prefValue = autoContinueListenable.value;
      if (mounted && _autoContinue != prefValue) {
        setState(() => _autoContinue = prefValue);
      }
    };
    autoContinueListenable.addListener(_autoContinueListener!);
    _load();
  }

  @override
  void dispose() {
    if (_autoContinueListener != null) {
      autoContinueListenable.removeListener(_autoContinueListener!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = UserPrefs();
    final name = await prefs.getUserName();
    final w = await prefs.getDefaultWorkMinutes();
    final b = await prefs.getDefaultBreakMinutes();
    final ac = await prefs.getAutoContinue();
    // Alarm sound disabled; skip loading ringtone.
    setState(() {
      _name = name;
      _work = w;
      _break = b;
      _autoContinue = ac;
      _loading = false;
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName == null) return;
    await UserPrefs().setUserName(newName);
    setState(() => _name = newName.isEmpty ? 'User' : newName);
  }

  Future<void> _editNumber({required String title, required int initial, required ValueChanged<int> onSaved}) async {
    final controller = TextEditingController(text: initial.toString());
    final res = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Minutes'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ?? initial;
              Navigator.pop(context, v < 1 ? 1 : v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == null) return;
    onSaved(res);
    await UserPrefs().setDefaultDurations(workMinutes: _work, breakMinutes: _break);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Defaults saved')));
  }

  // Alarm picking removed.

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _header('Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(_name),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editName,
          ),
          const Divider(height: 0),

          _header('Timer'),
          ListTile(
            leading: const Icon(Icons.work_history),
            title: const Text('Work minutes'),
            subtitle: Text('$_work minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNumber(title: 'Work minutes', initial: _work, onSaved: (v) => setState(() => _work = v)),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.free_breakfast),
            title: const Text('Break minutes'),
            subtitle: Text('$_break minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editNumber(title: 'Break minutes', initial: _break, onSaved: (v) => setState(() => _break = v)),
          ),
          const Divider(height: 0),
          SwitchListTile(
            secondary: const Icon(Icons.autorenew),
            title: const Text('Auto-continue to next phase'),
            value: _autoContinue,
            onChanged: (v) async {
              await UserPrefs().setAutoContinue(v);
            },
          ),

          _header('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Striktnanay'),
            subtitle: const Text('Learn more about the app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
      );
}
