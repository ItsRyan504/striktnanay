import 'package:shared_preferences/shared_preferences.dart';

class TimerPersistence {
  static const _kPhase = 'timer_phase';
  static const _kIsRunning = 'timer_is_running';
  static const _kTargetEpoch = 'timer_target_epoch_ms';
  static const _kTotalSeconds = 'timer_total_seconds';
  static const _kCompleted = 'timer_completed_sessions';
  static const _kWorkMinutes = 'timer_work_minutes';
  static const _kBreakMinutes = 'timer_break_minutes';

  Future<void> save({
    required String phase, // 'work' | 'break'
    required bool isRunning,
    required int targetEpochMs, // 0 if not running
    required int totalSeconds,
    required int completedSessions,
    required int workMinutes,
    required int breakMinutes,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPhase, phase);
    await sp.setBool(_kIsRunning, isRunning);
    await sp.setInt(_kTargetEpoch, targetEpochMs);
    await sp.setInt(_kTotalSeconds, totalSeconds);
    await sp.setInt(_kCompleted, completedSessions);
    await sp.setInt(_kWorkMinutes, workMinutes);
    await sp.setInt(_kBreakMinutes, breakMinutes);
  }

  Future<Map<String, Object?>?> read() async {
    final sp = await SharedPreferences.getInstance();
    if (!sp.containsKey(_kPhase)) return null;
    return {
      'phase': sp.getString(_kPhase),
      'isRunning': sp.getBool(_kIsRunning) ?? false,
      'targetEpochMs': sp.getInt(_kTargetEpoch) ?? 0,
      'totalSeconds': sp.getInt(_kTotalSeconds) ?? 0,
      'completedSessions': sp.getInt(_kCompleted) ?? 0,
      'workMinutes': sp.getInt(_kWorkMinutes) ?? 25,
      'breakMinutes': sp.getInt(_kBreakMinutes) ?? 5,
    };
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kPhase);
    await sp.remove(_kIsRunning);
    await sp.remove(_kTargetEpoch);
    await sp.remove(_kTotalSeconds);
    await sp.remove(_kCompleted);
    await sp.remove(_kWorkMinutes);
    await sp.remove(_kBreakMinutes);
  }
}
