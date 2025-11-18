import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _taskNameController = TextEditingController();
  final _subtaskControllers = <TextEditingController>[];
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String _repeatOption = 'Once';
  Color _selectedColor = const Color(0xFF14A085);
  List<String> _subtasks = [];

  final List<String> _categories = ['Studying', 'Chores', 'Work'];
  final List<String> _repeatOptions = ['Once', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    // Add one initial subtask field
    _addSubtaskField();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    for (var controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtaskField() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
      _subtasks.add('');
    });
  }

  // Future extension: Allow removing subtask fields
  // void _removeSubtaskField(int index) {
  //   if (_subtaskControllers.length > 1) {
  //     setState(() {
  //       _subtaskControllers[index].dispose();
  //       _subtaskControllers.removeAt(index);
  //       _subtasks.removeAt(index);
  //     });
  //   }
  // }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D7377),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._categories.map((category) => ListTile(
                    title: Text(category),
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      Navigator.pop(context);
                    },
                  )),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Custom…'),
                onTap: () async {
                  Navigator.pop(context);
                  final controller = TextEditingController(text: _selectedCategory ?? '');
                  final custom = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Custom Category'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'Enter category'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                      ],
                    ),
                  );
                  if (custom != null && custom.isNotEmpty) {
                    setState(() => _selectedCategory = custom);
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('None'),
                onTap: () {
                  setState(() => _selectedCategory = null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRepeatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _repeatOptions.map((option) {
              return ListTile(
                title: Text(option),
                onTap: () {
                  setState(() => _repeatOption = option);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
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
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color
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

  void _saveTask() {
    if (_taskNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    // Collect non-empty subtasks
    final validSubtasks = <Subtask>[];
    for (int i = 0; i < _subtaskControllers.length; i++) {
      final text = _subtaskControllers[i].text.trim();
      if (text.isNotEmpty) {
        validSubtasks.add(Subtask(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
          name: text,
        ));
      }
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _taskNameController.text.trim(),
      subtasks: validSubtasks,
      category: _selectedCategory,
      startDate: _startDate,
      dueDate: _endDate,
      repeatOption: _repeatOption,
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
    );

    Navigator.pop(context, task);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'MM/DD/YYYY';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Title and Save Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _saveTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14A085),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Task Name
                    _buildInputField(
                      controller: _taskNameController,
                      hint: 'Task Name',
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Color',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showColorPicker,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Subtasks
                    const Text(
                      'Subtasks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: List.generate(
                              _subtaskControllers.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildInputField(
                                  controller: _subtaskControllers[index],
                                  hint: 'Subtask ${index + 1}',
                                  onChanged: (value) {
                                    setState(() {
                                      _subtasks[index] = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addSubtaskField,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14A085),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Category
                    _buildSelectField(
                      label: 'Category',
                      value: _selectedCategory ?? 'Category',
                      onTap: _showCategoryPicker,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Start Date
                    _buildSelectField(
                      label: 'Start',
                      value: _formatDate(_startDate),
                      onTap: () => _selectDate(true),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // End Date
                    _buildSelectField(
                      label: 'End',
                      value: _formatDate(_endDate),
                      onTap: () => _selectDate(false),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Repeat
                    _buildSelectField(
                      label: 'Repeat',
                      value: _repeatOption,
                      onTap: _showRepeatPicker,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Add Image
                    Row(
                      children: [
                        const Text(
                          'Add Image (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement image picker
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image picker coming soon'),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14A085),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D7377),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Strikt Nanay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D7377),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 16),
                child: suffix,
              )
            : null,
      ),
    );
  }

  Widget _buildSelectField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: value == 'Category' ||
                              value == 'MM/DD/YYYY'
                          ? Colors.grey[400]
                          : const Color(0xFF333333),
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}

