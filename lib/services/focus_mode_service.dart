import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import '../models/task.dart';
import '../widgets/focus_overlay.dart';

class FocusModeService {
  static final FocusModeService _instance = FocusModeService._internal();
  factory FocusModeService() => _instance;
  FocusModeService._internal();

  static const MethodChannel _channel = MethodChannel('com.striktnanay.app/focus_mode');
  
  Timer? _monitoringTimer;
  bool _isActive = false;
  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;
  final StorageService _storageService = StorageService();
  String? _lastAppPackage;
  DateTime? _lastOverlayShownAt;
  
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
      final result = await Permission.systemAlertWindow.request();
      if (!result.isGranted) {
        return false;
      }
    }

    // Check usage stats permission
    try {
      final hasUsagePermission = await _channel.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
      return hasUsagePermission;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  Future<bool> showUsagePermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Usage Access Permission Required'),
        content: const Text(
          'Strikt Nanay needs Usage Access permission to monitor which apps you\'re using. '
          'Please enable it in Settings to use Focus Mode.\n\n'
          '1. Tap "Open Settings" below\n'
          '2. Find "Strikt Nanay" in the list\n'
          '3. Toggle the switch to enable Usage Access',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              try {
                await _channel.invokeMethod('openUsageStatsSettings');
              } catch (e) {
                print('Error opening usage stats settings: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable Usage Access in Settings manually'),
                    ),
                  );
                }
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> startMonitoring(BuildContext context, List<Task> tasks) async {
    if (_isActive) return true;

    // Check if there are unfinished tasks
    final hasUnfinishedTasks = tasks.any((task) => task.isCompleted == false);
    if (!hasUnfinishedTasks) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete all tasks first!')),
        );
      }
      return false;
    }

    // Check overlay permission first
    var hasOverlayPermission = await Permission.systemAlertWindow.isGranted;
    if (!hasOverlayPermission) {
      // Request overlay permission
      final result = await Permission.systemAlertWindow.request();
      hasOverlayPermission = result.isGranted;
      
      if (!hasOverlayPermission) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Overlay Permission Required'),
              content: const Text(
                'Strikt Nanay needs permission to display over other apps to show focus reminders. '
                'Please enable it in Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          
          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }
    }

    // Check usage stats permission
    try {
      final hasUsagePermission = await _channel.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
      if (!hasUsagePermission) {
        final shouldContinue = await showUsagePermissionDialog(context);
        if (!shouldContinue) {
          return false;
        }
        // Re-check after user returns from settings
        final recheckPermission = await _channel.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
        if (!recheckPermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usage Access permission is still not granted'),
              ),
            );
          }
          return false;
        }
      }
    } catch (e) {
      print('Error checking usage stats permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking permissions: $e')),
        );
      }
      return false;
    }

    _isActive = true;
    await _storageService.setFocusModeEnabled(true);

    // Get overlay state
    if (context.mounted) {
      _overlayState = Overlay.of(context);
    }

    // Start monitoring timer (check every 3 seconds)
    _monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (context.mounted) {
        _checkCurrentApp(context);
      }
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus Mode activated! Nanay is watching 👀'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return true;
  }

  Future<void> stopMonitoring() async {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isActive = false;
    await _storageService.setFocusModeEnabled(false);
    _hideOverlay();
  }

  Future<void> _checkCurrentApp(BuildContext context) async {
    if (!_isActive) return;

    try {
      final currentAppPackage = await _channel.invokeMethod<String>('getCurrentApp');
      
      if (currentAppPackage == null || currentAppPackage.isEmpty) {
        // Can't detect app, don't show overlay
        return;
      }

      // Don't show overlay if it's the same app as before
      if (currentAppPackage == _lastAppPackage) {
        return;
      }

      _lastAppPackage = currentAppPackage;

      final whitelist = await _storageService.getWhitelist();
      
      // Check if current app is whitelisted or is Strikt Nanay itself
      final isWhitelisted = whitelist[currentAppPackage] == true ||
          currentAppPackage == 'com.example.striktnanay'; // Your app's package name
      
      if (!isWhitelisted && _isActive) {
        final now = DateTime.now();
        final canShow = _overlayEntry == null && (
          _lastOverlayShownAt == null || now.difference(_lastOverlayShownAt!).inMinutes >= 1
        );
        if (canShow) {
          _lastOverlayShownAt = now;
          _showOverlay(context);
        }
      } else {
        _hideOverlay();
      }
    } catch (e) {
      print('Error checking current app: $e');
      // Don't show overlay on error
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

