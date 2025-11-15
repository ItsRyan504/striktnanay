import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import '../models/task.dart';
import '../widgets/focus_overlay.dart';

class FocusModeService {
  static final FocusModeService _instance = FocusModeService._internal();
  factory FocusModeService() => _instance;
  FocusModeService._internal();

  Timer? _monitoringTimer;
  bool _isActive = false;
  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;
  final StorageService _storageService = StorageService();
  final List<String> _reminderQuotes = [
    "Focus on your tasks, anak!",
    "Nanay is watching!",
    "Back to work!",
    "Your tasks are waiting!",
    "Stay focused!",
  ];

  bool get isActive => _isActive;

  Future<bool> checkPermissions() async {
    // Check overlay permission
    final overlayPermission = await Permission.systemAlertWindow.status;
    if (!overlayPermission.isGranted) {
      await Permission.systemAlertWindow.request();
    }

    // Check usage stats permission
    // Note: Usage stats permission requires special handling on Android
    // This is a simplified version - you'll need platform-specific code
    // For Android, you'd need to check Settings.ACTION_USAGE_ACCESS_SETTINGS
    
    return overlayPermission.isGranted;
  }

  Future<void> showUsagePermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usage Access Permission Required'),
        content: const Text(
          'Strikt Nanay needs Usage Access permission to monitor which apps you\'re using. '
          'Please enable it in Settings to use Focus Mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Open Android settings - requires platform-specific implementation
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> startMonitoring(BuildContext context, List<Task> tasks) async {
    if (_isActive) return;

    // Check if there are unfinished tasks
    final hasUnfinishedTasks = tasks.any((task) => task.isCompleted == false);
    if (!hasUnfinishedTasks) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete all tasks first!')),
        );
      }
      return;
    }

    // Check permissions
    final hasPermissions = await checkPermissions();
    if (!hasPermissions) {
      await showUsagePermissionDialog(context);
      return;
    }

    _isActive = true;
    await _storageService.setFocusModeEnabled(true);

    // Get overlay state
    _overlayState = Overlay.of(context);

    // Start monitoring timer (check every 3 seconds)
    _monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkCurrentApp(context);
    });
  }

  Future<void> stopMonitoring() async {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isActive = false;
    await _storageService.setFocusModeEnabled(false);
    _hideOverlay();
  }

  Future<void> _checkCurrentApp(BuildContext context) async {
    // This is a simplified version
    // In a real implementation, you'd use platform channels to get the current app
    // For now, we'll simulate the check
    
    final whitelist = await _storageService.getWhitelist();
    final currentAppPackage = 'com.example.distracting.app'; // Placeholder
    
    // Check if current app is whitelisted or is Strikt Nanay
    final isWhitelisted = whitelist[currentAppPackage] == true ||
        currentAppPackage == 'com.striktnanay.app'; // Replace with actual package name
    
    if (!isWhitelisted && _isActive) {
      _showOverlay(context);
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return; // Already showing

    final randomQuote = _reminderQuotes[
        DateTime.now().millisecondsSinceEpoch % _reminderQuotes.length];

    _overlayEntry = OverlayEntry(
      builder: (context) => FocusOverlay(
        quote: randomQuote,
        onDismiss: () => _hideOverlay(),
      ),
    );

    _overlayState?.insert(_overlayEntry!);

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _hideOverlay();
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void dispose() {
    stopMonitoring();
  }
}

