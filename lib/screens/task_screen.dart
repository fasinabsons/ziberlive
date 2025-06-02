import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../widgets/custom_widget.dart';
import 'package:uuid/uuid.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'All Tasks'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyTasksTab(),
          _AllTasksTab(),
        ],
      ),
      floatingActionButton: appState.currentUser?.isAdmin ?? false
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              child: const Icon(Icons.add_rounded),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOut)
          : null,
    );
  }
  
  void _showAddTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _AddTaskForm(),
      ),
    );
  }
}

class _MyTasksTab extends StatelessWidget {
  const _MyTasksTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    //final theme = Theme.of(context);
    
    final tasks = appState.userTasks;
    
    if (tasks.isEmpty) {
      return EmptyStateView(
        icon: Icons.task_alt_rounded,
        message: 'You don\'t have any tasks yet',
        actionLabel: appState.currentUser?.isAdmin ?? false ? 'Create Task' : null,
        onActionPressed: appState.currentUser?.isAdmin ?? false
            ? () {
                (context.findAncestorStateOfType<_TaskScreenState>() as _TaskScreenState)
                    ._showAddTaskDialog(context);
              }
            : null,
      );
    }
    
    // Separate tasks by completion status
    final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    
    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Task Summary
          _TaskSummaryWidget(
            incompleteCount: incompleteTasks.length,
            completedCount: completedTasks.length,
            totalCount: tasks.length,
          ),
          
          const SizedBox(height: 24),
          
          if (incompleteTasks.isNotEmpty) ...[            
            _buildSectionHeader(context, 'Pending Tasks', Icons.pending_actions_rounded),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incompleteTasks.length,
              itemBuilder: (context, index) {
                final task = incompleteTasks[index];
                return TaskItem(
                  title: task.title,
                  description: task.description,
                  dueDate: task.getFormattedDueDate(),
                  isCompleted: task.isCompleted,
                  creditReward: task.creditReward,
                  onComplete: () => appState.completeTask(task.id),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          
          if (completedTasks.isNotEmpty) ...[            
            _buildSectionHeader(context, 'Completed Tasks', Icons.check_circle_rounded),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                return TaskItem(
                  title: task.title,
                  description: task.description,
                  dueDate: task.getFormattedDueDate(),
                  isCompleted: task.isCompleted,
                  creditReward: task.creditReward,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.secondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _AllTasksTab extends StatelessWidget {
  const _AllTasksTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    //final theme = Theme.of(context);
    
    if (!appState.currentUser!.isAdmin) {
      return const Center(
        child: Text('Only admins can view all tasks'),
      );
    }
    
    final tasks = appState.tasks;
    
    if (tasks.isEmpty) {
      return EmptyStateView(
        icon: Icons.assignment_rounded,
        message: 'No tasks have been created yet',
        actionLabel: 'Create Task',
        onActionPressed: () {
          (context.findAncestorStateOfType<_TaskScreenState>() as _TaskScreenState)
              ._showAddTaskDialog(context);
        },
      );
    }
    
    // Group tasks by assigned user
    final Map<String, List<Task>> tasksByUser = {};
    
    for (var task in tasks) {
      if (!tasksByUser.containsKey(task.assignedUserId)) {
        tasksByUser[task.assignedUserId] = [];
      }
      tasksByUser[task.assignedUserId]!.add(task);
    }
    
    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Task Summary
          _AdminTaskSummaryWidget(
            totalCount: tasks.length,
            assignedUsers: tasksByUser.length,
          ),
          
          const SizedBox(height: 24),
          
          // Task completion progress
          _buildTaskCompletionProgress(context, tasks),
          
          const SizedBox(height: 24),
          
          // Tasks by user
          for (var userId in tasksByUser.keys) ...[            
            _buildUserTaskHeader(context, userId, tasksByUser[userId]!.length, appState),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasksByUser[userId]!.length,
              itemBuilder: (context, index) {
                final task = tasksByUser[userId]![index];
                return TaskItem(
                  title: task.title,
                  description: task.description,
                  dueDate: task.getFormattedDueDate(),
                  isCompleted: task.isCompleted,
                  creditReward: task.creditReward,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTaskCompletionProgress(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final completionRate = tasks.isNotEmpty ? completedCount / tasks.length : 0.0;
    
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Task Completion Rate',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(completionRate * 100).toInt()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completedCount of ${tasks.length} tasks completed',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: completionRate,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                      ),
                      Center(
                        child: Icon(
                          Icons.task_alt_rounded,
                          color: theme.colorScheme.secondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
  
  Widget _buildUserTaskHeader(BuildContext context, String userId, int taskCount, AppStateProvider appState) {
    final theme = Theme.of(context);
    final user = appState.users.firstWhere((u) => u.id == userId, orElse: () => User(
      id: userId,
      name: 'Unknown User',
      credits: 0,
      role: UserRole.guest,
    ));
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: user.name,
            size: 36,
            backgroundColor: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${user.role.name} • $taskCount task${taskCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            color: theme.colorScheme.secondary,
            onPressed: () {
              // Pre-select this user when creating a new task
              (context.findAncestorStateOfType<_TaskScreenState>() as _TaskScreenState)
                  ._showAddTaskDialog(context);
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _TaskSummaryWidget extends StatelessWidget {
  final int incompleteCount;
  final int completedCount;
  final int totalCount;
  
  const _TaskSummaryWidget({
    required this.incompleteCount,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tasks Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  count: incompleteCount,
                  label: 'Pending',
                  icon: Icons.pending_actions_rounded,
                  color: theme.colorScheme.error,
                ),
                _SummaryItem(
                  count: completedCount,
                  label: 'Completed',
                  icon: Icons.check_circle_rounded,
                  color: theme.colorScheme.secondary,
                ),
                _SummaryItem(
                  count: totalCount,
                  label: 'Total',
                  icon: Icons.assignment_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LabeledProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              label: 'Completion Progress',
              progressColor: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _AdminTaskSummaryWidget extends StatelessWidget {
  final int totalCount;
  final int assignedUsers;
  
  const _AdminTaskSummaryWidget({
    required this.totalCount,
    required this.assignedUsers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Task Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  count: totalCount,
                  label: 'Total Tasks',
                  icon: Icons.assignment_rounded,
                  color: theme.colorScheme.secondary,
                ),
                _SummaryItem(
                  count: assignedUsers,
                  label: 'Assigned Users',
                  icon: Icons.people_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  
  const _SummaryItem({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }
}

class _AddTaskForm extends StatefulWidget {
  const _AddTaskForm();

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditRewardController = TextEditingController(text: '10');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedUserId;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _creditRewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Task',
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Task Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g. Clean the kitchen',
                prefixIcon: Icon(Icons.title_rounded, color: theme.colorScheme.secondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title for the task';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Task Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Provide details about what needs to be done',
                prefixIcon: Icon(Icons.description_rounded, color: theme.colorScheme.secondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Due Date
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Text(
                  'Due Date: ${DateFormat.yMMMd().format(_dueDate)}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dueDate = pickedDate;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Credit Reward
            TextFormField(
              controller: _creditRewardController,
              decoration: InputDecoration(
                labelText: 'Credit Reward',
                hintText: 'Credits to award when completed',
                prefixIcon: Icon(Icons.stars_rounded, color: theme.colorScheme.tertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a credit reward';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Assign To User
            Text(
              'Assign To User',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appState.users.length,
                    itemBuilder: (context, index) {
                      final user = appState.users[index];
                     // final isSelected = _selectedUserId == user.id;
                      
                      return RadioListTile<String>(
                        title: Text(user.name),
                        subtitle: Text(
                          'Role: ${user.role.name}',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: user.id,
                        groupValue: _selectedUserId,
                        onChanged: (value) {
                          setState(() {
                            _selectedUserId = value;
                          });
                        },
                        activeColor: theme.colorScheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Create Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && _selectedUserId != null) {
                  final newTask = Task(
                    id: const Uuid().v4(),
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    dueDate: _dueDate,
                    assignedUserId: _selectedUserId!,
                    creditReward: int.parse(_creditRewardController.text.trim()),
                  );
                  
                  appState.createTask(newTask);
                  Navigator.pop(context);
                } else if (_selectedUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a user to assign this task')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}