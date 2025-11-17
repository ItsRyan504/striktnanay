import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/storage_service.dart';
import '../services/task_sync.dart';
import 'task_detail_screen.dart';
import 'whitelist_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void refresh() {
    _loadTasks();
  }
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_onSearchChanged);
    _syncListener = () { _loadTasks(); };
    TaskSync.instance.version.addListener(_syncListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    TaskSync.instance.version.removeListener(_syncListener);
    super.dispose();
  }

  late VoidCallback _syncListener;

  void _onSearchChanged() {
    _filterTasks();
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredTasks = _tasks;
      });
    } else {
      setState(() {
        _filteredTasks = _tasks.where((task) {
          return task.name.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _storageService.getTasks();
    setState(() {
      _tasks = tasks;
      _filteredTasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> _getTasksForDate(DateTime date) {
    final tasksToSearch = _isSearching ? _filteredTasks : _tasks;
    return tasksToSearch.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      final compareDate = DateTime(date.year, date.month, date.day);
      return taskDate.isAtSameMomentAs(compareDate);
    }).toList();
  }

  bool _hasTaskOnDate(DateTime date) {
    return _getTasksForDate(date).isNotEmpty;
  }

  Future<void> _toggleSubtask(Task task, Subtask subtask) async {
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtask.id) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    // Auto-complete task if all subtasks are done
    final allCompleted = updatedSubtasks.isNotEmpty &&
        updatedSubtasks.every((s) => s.isCompleted);
    
    final updatedTask = task.copyWith(
      subtasks: updatedSubtasks,
      isCompleted: allCompleted ? true : task.isCompleted,
    );

    final tasks = await _storageService.getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await _storageService.saveTasks(tasks);
      // Reload tasks to sync with home screen
      await _loadTasks();
      setState(() {}); // Update UI immediately
    }
  }

  void _openWhitelist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WhitelistScreen()),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    List<DateTime> days = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(0)); // Placeholder
    }
    
    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    return days;
  }

  String _getMonthName() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[_currentMonth.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Calendar Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar (when active)
                          if (_isSearching) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search tasks...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  icon: const Icon(Icons.search, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                          
                          // Calendar Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Calendar',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _previousMonth,
                                    icon: const Icon(Icons.chevron_left),
                                    color: const Color(0xFF0D7377),
                                  ),
                                  IconButton(
                                    onPressed: _nextMonth,
                                    icon: const Icon(Icons.chevron_right),
                                    color: const Color(0xFF0D7377),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_getMonthName()} ${_currentMonth.year}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Calendar Grid
                          _buildCalendarGrid(),
                          const SizedBox(height: 32),
                          
                          // Tasks Section
                          _buildTasksSection(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Profile Icon (Nanay)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF0D7377),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          // App Name
          const Text(
            'Strikt Nanay',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D7377),
            ),
          ),
          const Spacer(),
          // Search Bar
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterTasks();
                }
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.grey[700],
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Whitelist Button
          IconButton(
            onPressed: _openWhitelist,
            icon: const Icon(
              Icons.shield,
              color: Color(0xFF0D7377),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _getDaysInMonth();
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Column(
      children: [
        // Weekday headers
        Row(
          children: weekdays.map((day) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Calendar days
        ...List.generate((days.length / 7).ceil(), (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final index = weekIndex * 7 + dayIndex;
              if (index >= days.length) {
                return const Expanded(child: SizedBox());
              }
              
              final date = days[index];
              if (date.year == 0) {
                // Empty cell
                return const Expanded(child: SizedBox());
              }
              
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final hasTask = _hasTaskOnDate(date);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.grey[300]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFF0D7377), width: 2)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF333333)
                                    : const Color(0xFF333333),
                              ),
                            ),
                            if (hasTask)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5DADE2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildTasksSection() {
    final tasksForDate = _isSearching 
        ? _filteredTasks 
        : _getTasksForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSearching ? 'Search Results' : 'Tasks',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        if (_isSearching && _searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${tasksForDate.length} task${tasksForDate.length != 1 ? 's' : ''} found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (tasksForDate.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                _isSearching
                    ? 'No tasks found matching "${_searchController.text}"'
                    : 'No tasks for ${_formatDate(_selectedDate)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ...tasksForDate.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    Color cardColor;
    Color textColor;
    if (task.color != null && task.color!.isNotEmpty) {
      try {
        cardColor = Color(int.parse(task.color!.replaceFirst('#', '0xFF')));
        textColor = _getContrastColor(cardColor);
      } catch (e) {
        cardColor = task.isCompleted
            ? const Color(0xFF9B59B6)
            : const Color(0xFF5DADE2);
        textColor = task.isCompleted ? Colors.white : const Color(0xFF333333);
      }
    } else {
      cardColor = task.isCompleted
          ? const Color(0xFF9B59B6)
          : const Color(0xFF5DADE2);
      textColor = task.isCompleted ? Colors.white : const Color(0xFF333333);
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              onTaskUpdated: (updatedTask) async {
                await _loadTasks();
                setState(() {});
              },
              onTaskDeleted: (taskId) async {
                await _loadTasks();
                setState(() {});
              },
            ),
          ),
        );
        await _loadTasks();
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title and Due Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (task.dueDate != null)
                  Text(
                    'DUE ${_formatDate(task.dueDate!)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Subtasks
              ...task.subtasks.map((subtask) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _toggleSubtask(task, subtask),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: (value) => _toggleSubtask(task, subtask),
                            activeColor: textColor,
                            checkColor: cardColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            subtask.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF333333) : Colors.white;
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}
