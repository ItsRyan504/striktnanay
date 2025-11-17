import 'package:flutter/foundation.dart';

/// Simple global synchronization primitive for task updates.
/// Screens listen to [version] and reload tasks whenever it increments.
class TaskSync {
  TaskSync._();
  static final TaskSync instance = TaskSync._();

  /// Incrementing counter to signal changes. We use an int so listeners
  /// always trigger even if task list contents are structurally identical.
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  void notifyChanged() {
    version.value = version.value + 1;
  }
}