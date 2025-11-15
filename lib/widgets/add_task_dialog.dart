import 'package:flutter/material.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Add Task',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D7377),
        ),
      ),
      content: TextField(
        controller: _taskController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Task Name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF0D7377),
              width: 2,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_taskController.text.trim().isNotEmpty) {
              Navigator.pop(context, _taskController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D7377),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

