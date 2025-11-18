import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Removed storage dependency for session-only counters
import '../services/notification_service.dart';

enum PomodoroPhase { work, breakTime }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Configuration
  int _workMinutes = 25;
  int _breakMinutes = 5;
  bool _useRecommended = true;
  bool _showCustomInputs = false;

  // Runtime state
  PomodoroPhase _phase = PomodoroPhase.work;
  int _remainingSeconds = 25 * 60; // start with work phase
  int _totalPhaseSeconds = 25 * 60;
  int _completedWorkSessions = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _autoContinue = true; // auto move to next phase or wait for user
  final int _dailyPomodoroGoal = 4;
  // Removed persisted completed tasks; we show a session-only counter
  int _manualCompletedTasks = 0; // user-adjusted count via +/-
  bool _nagOpen = false;
  final NotificationService _notif = NotificationService();
  static const int _notifIdWork = 100;
  static const int _notifIdBreak = 101;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _startTimer() {
    if (_isRunning) return;
    _scheduleForCurrentPhase();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        _onPhaseComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _cancelScheduled();
    setState(() => _isRunning = false);
    _showPausePopup();
  }

  void _resetTimer({bool keepMode = true}) {
    _timer?.cancel();
    _cancelScheduled();
    setState(() {
      _isRunning = false;
      if (!keepMode) {
        _phase = PomodoroPhase.work;
        _completedWorkSessions = 0;
      }
      final minutes = _phase == PomodoroPhase.work ? _workMinutes : _breakMinutes;
      _remainingSeconds = minutes * 60;
      _totalPhaseSeconds = _remainingSeconds;
    });
  }

  void _switchPhase() {
    setState(() {
      if (_phase == PomodoroPhase.work) {
        _phase = PomodoroPhase.breakTime;
        _remainingSeconds = _breakMinutes * 60;
        _totalPhaseSeconds = _remainingSeconds;
      } else {
        _phase = PomodoroPhase.work;
        _remainingSeconds = _workMinutes * 60;
        _totalPhaseSeconds = _remainingSeconds;
      }
    });
    if (_isRunning) {
      _scheduleForCurrentPhase();
    }
  }

  void _onPhaseComplete() async {
    // Alarm sound (system alert)
    SystemSound.play(SystemSoundType.alert);
    _cancelScheduled();

    if (_phase == PomodoroPhase.work) {
      _completedWorkSessions++;
    }

    if (!_autoContinue) {
      _showCompletionDialog();
      return;
    }

    _showCompletionDialog(auto: true);
  }

  Future<void> _scheduleForCurrentPhase() async {
    final ok = await _notif.ensurePermission();
    if (!ok) return;
    final isWork = _phase == PomodoroPhase.work;
    final id = isWork ? _notifIdWork : _notifIdBreak;
    final title = isWork ? 'Work session complete' : 'Break over';
    final body = isWork ? 'Great job! Time for a break.' : 'Ready to focus again?';
    await _notif.cancel(id);
    await _notif.scheduleIn(title: title, body: body, inFromNow: Duration(seconds: _remainingSeconds), id: id);
  }

  Future<void> _cancelScheduled() async {
    await _notif.cancel(_notifIdWork);
    await _notif.cancel(_notifIdBreak);
  }

  void _showCompletionDialog({bool auto = false}) {
    final nextIsBreak = _phase == PomodoroPhase.work;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(nextIsBreak ? 'Work Session Complete!' : 'Break Over!'),
          content: Text(nextIsBreak
              ? 'Great job. Time for a break.'
              : 'Break finished. Ready for another focus session?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _switchPhase();
                _resetTimer();
                if (auto) {
                  _startTimer();
                }
              },
              child: Text(nextIsBreak ? 'Start Break' : 'Start Work'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _switchPhase();
                _resetTimer();
              },
              child: const Text('Later'),
            ),
          ],
        );
      },
    );
  }

  void _showPausePopup() {
    if (_nagOpen) return;
    _nagOpen = true;
    final rnd = Random();
    const messages = [
      'Puro ka laro! Mag-aral ka muna!',
      'Kita ko ’yan! Balik sa ginagawa mo.',
      'Konti na lang, kaya mo ’yan!',
      'Focus muna, anak. Tapos laro.',
      'Wag susuko, tatapusin natin ’to.',
    ];
    final msg = messages[rnd.nextInt(messages.length)];
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _AutoCloseDialog(message: msg, seconds: 5);
      },
    ).then((_) {
      _nagOpen = false;
    });
  }

  void _applyCustom() {
    // Ensure reasonable limits
    if (_workMinutes < 1) _workMinutes = 1;
    if (_breakMinutes < 1) _breakMinutes = 1;
    setState(() {
      _useRecommended = false;
      _phase = PomodoroPhase.work;
      _remainingSeconds = _workMinutes * 60;
      _totalPhaseSeconds = _remainingSeconds;
      _isRunning = false;
    });
  }

  double get _progress => 1 - (_remainingSeconds / _totalPhaseSeconds);

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF0D7377);
    final isWork = _phase == PomodoroPhase.work;
    final initial = _isInitial();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header / Mode Switch
              Row(
                children: [
                  Text(
                    'Pomodoro Timer',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _autoContinue
                        ? 'Auto-continue enabled (tap to disable)'
                        : 'Auto-continue disabled (tap to enable)',
                    onPressed: () => setState(() => _autoContinue = !_autoContinue),
                    icon: Icon(
                      _autoContinue ? Icons.autorenew : Icons.handyman,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recommended / Custom toggle
              Row(
                children: [
                  _modeChip('Recommended', _useRecommended, () {
                    setState(() {
                      _useRecommended = true;
                      _showCustomInputs = false;
                      _workMinutes = 25;
                      _breakMinutes = 5;
                      _applyCustom();
                    });
                  }),
                  const SizedBox(width: 12),
                  _modeChip('Custom', !_useRecommended, () {
                    setState(() {
                      if (_useRecommended) {
                        // first time switching to custom
                        _useRecommended = false;
                        _showCustomInputs = true;
                      } else {
                        // already in custom; toggle visibility
                        _showCustomInputs = !_showCustomInputs;
                      }
                    });
                  }),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showCustomInputs
                    ? _buildCustomInputs(themeColor)
                    : const SizedBox.shrink(),
              ),

              // Timer Circle
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 14,
                        backgroundColor: themeColor.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWork ? themeColor : Colors.orange,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isWork ? 'Focus' : 'Break',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isWork ? themeColor : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _format(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Session: $_completedWorkSessions',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Today's Progress Card
              _buildTodayProgressCard(themeColor),
              const SizedBox(height: 16),

              // Controls
              _buildControls(themeColor, initial),
            ],
          ),
        ),
      ),
    );
  }

  bool _isInitial() => !_isRunning && _remainingSeconds == _totalPhaseSeconds;

  Widget _buildControls(Color themeColor, bool initial) {
    if (initial) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            icon: Icons.play_arrow,
            label: 'Start',
            color: themeColor,
            onTap: () {
              // Do not reset unless custom durations changed; durations already set
              _startTimer();
            },
          ),
        ],
      );
    }

    // Running or paused state
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(
          icon: _isRunning ? Icons.pause : Icons.play_arrow,
          label: _isRunning ? 'Pause' : 'Resume',
          color: themeColor,
          onTap: _isRunning ? _pauseTimer : _startTimer,
        ),
        const SizedBox(width: 16),
        _controlButton(
          icon: Icons.skip_next,
          label: 'Skip',
          color: Colors.orange,
          onTap: () {
            _pauseTimer();
            _switchPhase();
            _resetTimer();
          },
        ),
        const SizedBox(width: 16),
        _controlButton(
          icon: Icons.stop,
          label: 'Reset',
          color: Colors.red,
          onTap: () => _resetTimer(keepMode: true),
        ),
      ],
    );
  }

  Widget _buildTodayProgressCard(Color themeColor) {
    final completed = _completedWorkSessions;
    final goal = _dailyPomodoroGoal;
    final progress = goal == 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);

    // Focused time: completed work sessions + elapsed in current work session
    final currentWorkElapsed = _phase == PomodoroPhase.work
        ? (_totalPhaseSeconds - _remainingSeconds)
        : 0;
    final focusedSeconds = (completed * _workMinutes * 60) + currentWorkElapsed;

    String formatHM(int seconds) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      if (h > 0) {
        return '${h}h ${m}m';
      }
      return '${m}m';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final stats = [
                _statRow(Icons.local_fire_department, 'Pomodoros', '$completed', themeColor),
                _statRow(Icons.timer_outlined, 'Focused time', formatHM(focusedSeconds), themeColor),
                _completedTasksRow(themeColor),
              ];

              return isNarrow
                  ? Column(children: [for (final s in stats) ...[s, const SizedBox(height: 8)]])
                  : Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: stats
                          .map((s) => SizedBox(
                                width: (constraints.maxWidth - 12) / 2,
                                child: s,
                              ))
                          .toList(),
                    );
            },
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completed <= goal
                ? '$completed of $goal Pomodoros completed'
                : '$completed of $goal Pomodoros completed (+${completed - goal})',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeChip(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0D7377) : const Color(0xFF14A085),
          borderRadius: BorderRadius.circular(30),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Completed tasks row with +/- controls
  Widget _completedTasksRow(Color color) {
    // Session-only tally so it can go down to zero
    final value = _manualCompletedTasks;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check_circle_outline, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Tasks finished (session)', style: TextStyle(color: Color(0xFF828282), fontSize: 12)),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniIconButton(Icons.remove, color, () {
              setState(() {
                if (_manualCompletedTasks > 0) _manualCompletedTasks--;
              });
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$value', style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600)),
            ),
            _miniIconButton(Icons.add, color, () {
              setState(() {
                _manualCompletedTasks++;
              });
            }),
          ],
        )
      ],
    );
  }

  Widget _miniIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildCustomInputs(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Durations (minutes)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _numberField(
                label: 'Work',
                initial: _workMinutes,
                onChanged: (v) => _workMinutes = v,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _numberField(
                label: 'Break',
                initial: _breakMinutes,
                onChanged: (v) => _breakMinutes = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: _applyCustom,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _numberField({required String label, required int initial, required ValueChanged<int> onChanged}) {
    final controller = TextEditingController(text: initial.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Minutes'),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? initial;
              onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }

  Widget _controlButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 34),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }
}

class _AutoCloseDialog extends StatefulWidget {
  const _AutoCloseDialog({required this.message, required this.seconds});
  final String message;
  final int seconds;

  @override
  State<_AutoCloseDialog> createState() => _AutoCloseDialogState();
}

class _AutoCloseDialogState extends State<_AutoCloseDialog> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF0D7377);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: teal, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.sentiment_very_dissatisfied, color: teal, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    '“${widget.message}”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Closes in ${_remaining}s…',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
            )
          ],
        ),
      ),
    );
  }
}

