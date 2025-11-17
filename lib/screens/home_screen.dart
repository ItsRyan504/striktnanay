import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/task_sync.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final StorageService _storageService = StorageService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredTasks = [];
    _loadData();
    _syncListener = () { _loadData(); };
    TaskSync.instance.version.addListener(_syncListener);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    TaskSync.instance.version.removeListener(_syncListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  late VoidCallback _syncListener;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app comes back to foreground
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tasks = await _storageService.getTasks();
    setState(() {
      _tasks = tasks;
      _filterTasks();
      _isLoading = false;
    });
  }

  void _filterTasks() {
    Iterable<Task> list = _tasks;
    if (_selectedCategory != null) {
      list = list.where((task) => task.category == _selectedCategory);
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(q));
    }
    _filteredTasks = list.toList();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
      _filterTasks();
    });
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );

    if (result != null) {
      _tasks.add(result);
      await _storageService.saveTasks(_tasks);
      _filterTasks();
      setState(() {});
    }
  }

  Future<void> _openTaskDetail(Task task) async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          onTaskUpdated: (updatedTask) {
            final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
            if (index != -1) {
              _tasks[index] = updatedTask;
              _storageService.saveTasks(_tasks);
              _filterTasks();
              setState(() {});
            }
          },
          onTaskDeleted: (taskId) {
            _tasks.removeWhere((t) => t.id == taskId);
            _storageService.saveTasks(_tasks);
            _filterTasks();
            setState(() {});
          },
        ),
      ),
    );

    if (updatedTask != null) {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        await _storageService.saveTasks(_tasks);
        _filterTasks();
        setState(() {});
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    _tasks.removeWhere((t) => t.id == task.id);
    await _storageService.saveTasks(_tasks);
    _filterTasks();
    setState(() {});
  }


  // Removed Whitelist navigation from Home header

  Future<void> _startSearch() async {
    final selected = await showSearch<Task?>(
      context: context,
      delegate: _TaskSearchDelegate(tasks: _tasks),
    );
    if (selected != null) {
      _openTaskDetail(selected);
    }
  }

  int get _pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get _completedTasksCount => _tasks.where((t) => t.isCompleted).length;

  void refresh() {
    _loadData();
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
            
            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Greeting
                          _buildGreeting(),
                          
                          const SizedBox(height: 24),
                          
                          // Status Cards
                          _buildStatusCards(),
                          
                          const SizedBox(height: 32),
                          
                          // Categories Section
                          _buildCategoriesSection(),
                          
                            const SizedBox(height: 24),
                          
                          // Progress Section (Tasks)
                          _buildProgressSection(),
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            onTap: _startSearch,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return const Center(
      child: Text(
        'Hello, User!',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Galit si Nanay!',
            subtitle: '$_pendingTasksCount Tasks are Pending',
            isAngry: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            title: 'Happy na si Nanay!',
            subtitle: '$_completedTasksCount Tasks are Complete',
            isAngry: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required bool isAngry,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14A085), Color(0xFF0D7377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nanay Icon with expression
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 4),
              if (isAngry)
                const Icon(
                  Icons.mood_bad,
                  color: Colors.white,
                  size: 20,
                )
              else
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryButton('Studying'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryButton('Chores'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryButton('Work'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF0D7377) 
              : const Color(0xFF14A085),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF0D7377), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_filteredTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            _selectedCategory != null
                ? 'No tasks in $_selectedCategory category.\nTap a category to filter or add a task!'
                : 'No tasks yet. Tap the + button to add one!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredTasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    // Use the task's progress percentage getter
    final progress = task.progressPercentage;
    
    // Determine card color
    Color cardColor;
    Color textColor;
    if (task.color != null && task.color!.isNotEmpty) {
      try {
        cardColor = Color(int.parse(task.color!.replaceFirst('#', '0xFF')));
        textColor = _getContrastColor(cardColor);
      } catch (e) {
        cardColor = task.isCompleted 
            ? const Color(0xFF9B59B6) // Purple for completed
            : const Color(0xFF5DADE2); // Light blue for incomplete
        textColor = task.isCompleted ? Colors.white : const Color(0xFF333333);
      }
    } else {
      cardColor = task.isCompleted 
          ? const Color(0xFF9B59B6) // Purple for completed
          : const Color(0xFF5DADE2); // Light blue for incomplete
      textColor = task.isCompleted ? Colors.white : const Color(0xFF333333);
    }

    return GestureDetector(
      onTap: () => _openTaskDetail(task),
      onLongPress: () {
        _deleteTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'DUE ${_formatDate(task.dueDate!)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Progress Indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 4,
                    backgroundColor: textColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
                Text(
                  '$progress%',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use white or black text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF333333) : Colors.white;
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14A085), Color(0xFF0D7377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addTask,
          borderRadius: BorderRadius.circular(12),
          child: const Icon(
            Icons.add_task,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

}

class _TaskSearchDelegate extends SearchDelegate<Task?> {
  _TaskSearchDelegate({required this.tasks});
  final List<Task> tasks;

  @override
  String get searchFieldLabel => 'Search tasks';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  Iterable<Task> _filter() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tasks;
    return tasks.where((t) => t.name.toLowerCase().contains(q));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filter().toList();
    return _buildList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _filter().toList();
    return _buildList(context, results);
  }

  Widget _buildList(BuildContext context, List<Task> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text('No matching tasks'),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = results[index];
        return ListTile(
          title: Text(t.name),
          subtitle: t.category != null ? Text(t.category!) : null,
          leading: const Icon(Icons.task_alt),
          onTap: () => close(context, t),
        );
      },
    );
  }
}
