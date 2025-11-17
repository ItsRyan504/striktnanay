import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/storage_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final Function(String)? onTaskDeleted;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    this.onTaskDeleted,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  final StorageService _storageService = StorageService();
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  bool _isEditingTask = false;
  bool _isEditingSubtask = false;
  Subtask? _editingSubtask;
  int _lastProgress = 0;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _taskNameController.text = _task.name;
    _lastProgress = _task.progressPercentage;
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    _taskNameController.dispose();
    super.dispose();
  }

  Future<void> _saveTask({bool shouldPop = false}) async {
    if (_isEditingTask) {
      setState(() {
        _task = _task.copyWith(name: _taskNameController.text.trim());
        _isEditingTask = false;
      });
    }
    
    final tasks = await _storageService.getTasks();
    final index = tasks.indexWhere((t) => t.id == _task.id);
    if (index != -1) {
      tasks[index] = _task;
      await _storageService.saveTasks(tasks);
      widget.onTaskUpdated(_task);
    }
    
    // Only pop if explicitly requested (e.g., from check button when not editing)
    if (shouldPop && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final tasks = await _storageService.getTasks();
      tasks.removeWhere((t) => t.id == _task.id);
      await _storageService.saveTasks(tasks);
      if (widget.onTaskDeleted != null) {
        widget.onTaskDeleted!(_task.id);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _startEditingTask() {
    setState(() {
      _isEditingTask = true;
    });
  }

  void _cancelEditingTask() {
    setState(() {
      _isEditingTask = false;
      _taskNameController.text = _task.name;
    });
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    if (_isEditingSubtask && _editingSubtask != null) {
      // Update existing subtask
      setState(() {
        final updatedSubtasks = _task.subtasks.map((s) {
          if (s.id == _editingSubtask!.id) {
            return s.copyWith(name: _subtaskController.text.trim());
          }
          return s;
        }).toList();
        _task = _task.copyWith(subtasks: updatedSubtasks);
        _isEditingSubtask = false;
        _editingSubtask = null;
      });
    } else {
      // Add new subtask
      setState(() {
        _task = _task.copyWith(
          subtasks: [
            ..._task.subtasks,
            Subtask(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _subtaskController.text.trim(),
            ),
          ],
        );
      });
    }

    _subtaskController.clear();
    _saveTask(shouldPop: false); // Save but don't pop
  }

  void _startEditingSubtask(Subtask subtask) {
    setState(() {
      _isEditingSubtask = true;
      _editingSubtask = subtask;
      _subtaskController.text = subtask.name;
    });
  }

  void _cancelEditingSubtask() {
    setState(() {
      _isEditingSubtask = false;
      _editingSubtask = null;
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(Subtask subtask) {
    setState(() {
      final updatedSubtasks = _task.subtasks.map((s) {
        if (s.id == subtask.id) {
          return s.copyWith(isCompleted: !s.isCompleted);
        }
        return s;
      }).toList();

      _task = _task.copyWith(subtasks: updatedSubtasks);

      // Auto-complete task if all subtasks are done
      if (updatedSubtasks.isNotEmpty &&
          updatedSubtasks.every((s) => s.isCompleted)) {
        _task = _task.copyWith(isCompleted: true);
      }
    });
    _handleProgressChange();
    _saveTask(shouldPop: false); // Save but don't pop
  }

  void _deleteSubtask(Subtask subtask) {
    setState(() {
      _task = _task.copyWith(
        subtasks: _task.subtasks.where((s) => s.id != subtask.id).toList(),
      );
    });
    _handleProgressChange();
    _saveTask(shouldPop: false); // Save but don't pop
  }

  Color _getTaskColor() {
    if (_task.color != null && _task.color!.isNotEmpty) {
      try {
        return Color(int.parse(_task.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return const Color(0xFF5DADE2);
      }
    }
    return const Color(0xFF5DADE2);
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = _getTaskColor();
    final progress = _task.progressPercentage;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: taskColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isEditingTask
            ? SizedBox(
                width: 200,
                child: TextField(
                  controller: _taskNameController,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Task name',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  onSubmitted: (_) => _saveTask(),
                ),
              )
            : Text(
                _task.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_isEditingTask)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _cancelEditingTask,
            ),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            tooltip: 'Change color',
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: Icon(_isEditingTask ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: _isEditingTask 
                ? () => _saveTask(shouldPop: false) // Save but stay on screen
                : _startEditingTask,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTask();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Task'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: taskColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$progress%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: taskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 8,
                          backgroundColor: taskColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(taskColor),
                        ),
                      ),
                      Text(
                        '$progress%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: taskColor,
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _showCelebration ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.check_circle,
                            color: taskColor.withOpacity(0.9),
                            size: 92,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Notepad Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Info
                    if (_task.dueDate != null) ...[
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${_formatDate(_task.dueDate!)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_task.category != null) ...[
                      Row(
                        children: [
                          Icon(Icons.label, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Category: ${_task.category}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Subtasks Section
                    Row(
                      children: [
                        const Text(
                          'Subtasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_task.subtasks.where((s) => s.isCompleted).length}/${_task.subtasks.length}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subtasks List
                    Expanded(
                      child: _task.subtasks.isEmpty
                          ? Center(
                              child: Text(
                                'No subtasks yet.\nTap + to add one!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _task.subtasks.length,
                              itemBuilder: (context, index) {
                                final subtask = _task.subtasks[index];
                                return _buildSubtaskItem(subtask);
                              },
                            ),
                    ),

                    // Add/Edit Subtask Input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              decoration: InputDecoration(
                                hintText: _isEditingSubtask
                                    ? 'Edit subtask...'
                                    : 'Add subtask...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          if (_isEditingSubtask)
                            IconButton(
                              onPressed: _cancelEditingSubtask,
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                            ),
                          IconButton(
                            onPressed: _addSubtask,
                            icon: Icon(
                              _isEditingSubtask ? Icons.check_circle : Icons.add_circle,
                              color: taskColor,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProgressChange() {
    final current = _task.progressPercentage;
    if (current == 100 && _lastProgress < 100) {
      setState(() {
        _showCelebration = true;
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showCelebration = false;
          });
        }
      });
    }
    _lastProgress = current;
  }

  void _showColorPicker() {
    final colors = [
      const Color(0xFF14A085), // Teal
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF5DADE2), // Light Blue
      const Color(0xFFE74C3C), // Red
      const Color(0xFFF39C12), // Orange
      const Color(0xFF2ECC71), // Green
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () async {
                final hex = '#${color.value.toRadixString(16).substring(2)}';
                setState(() {
                  _task = _task.copyWith(color: hex);
                });
                Navigator.pop(context);
                await _saveTask(shouldPop: false);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getTaskColor() == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubtaskItem(Subtask subtask) {
    final isEditing = _isEditingSubtask && _editingSubtask?.id == subtask.id;
    
    return Dismissible(
      key: Key(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteSubtask(subtask),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: subtask.isCompleted
                ? Colors.green.withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: subtask.isCompleted,
              onChanged: isEditing ? null : (_) => _toggleSubtask(subtask),
              activeColor: _getTaskColor(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: _subtaskController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    )
                  : GestureDetector(
                      onTap: () => _startEditingSubtask(subtask),
                      child: Text(
                        subtask.name,
                        style: TextStyle(
                          fontSize: 16,
                          decoration: subtask.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: subtask.isCompleted
                              ? Colors.grey[500]
                              : const Color(0xFF333333),
                        ),
                      ),
                    ),
            ),
            if (!isEditing) ...[
              IconButton(
                onPressed: () => _startEditingSubtask(subtask),
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteSubtask(subtask),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red[400],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}

