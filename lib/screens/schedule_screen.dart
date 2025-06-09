import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state_provider.dart';
import '../models/user_model.dart'; // Assuming User model is here
import '../models/schedule_models.dart';
import '../widgets/custom_widget.dart'; // Assuming EmptyStateView and CustomCard are here

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // "Calendar" and "Laundry"
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getUserName(String userId, AppStateProvider appState) {
    try {
      return appState.users.firstWhere((u) => u.id == userId).name;
    } catch (e) {
      return 'ID: $userId'; // Fallback if user not found
    }
  }

  void _showAddScheduleDialog(BuildContext context, AppStateProvider appState, {Schedule? existingSchedule}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => _AddScheduleForm(
          appState: appState,
          existingSchedule: existingSchedule,
          getUserName: _getUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules & Tasks'), // Updated title
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar & Tasks'), // Updated tab label
            Tab(text: 'Laundry'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CalendarTab(
            appState: appState,
            showAddDialog: (Schedule? schedule) => _showAddScheduleDialog(context, appState, existingSchedule: schedule),
            getUserName: _getUserName,
          ),
          _LaundryTab(
            appState: appState,
            getUserName: _getUserName,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context, appState),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        heroTag: 'add_schedule_or_task', // Updated heroTag
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  final AppStateProvider appState;
  final Function(Schedule? schedule) showAddDialog;
  final String Function(String userId, AppStateProvider appState) getUserName;

  const _CalendarTab({required this.appState, required this.showAddDialog, required this.getUserName});

  void _editScheduleWrapper(BuildContext context, Schedule schedule) {
    showAddDialog(schedule);
  }

  void _deleteScheduleWrapper(BuildContext context, Schedule schedule) {
    String itemType = schedule.type.toString().split('.').last;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemType'),
        content: Text('Are you sure you want to delete "${schedule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first
              try {
                if (schedule.type == ScheduleType.task) {
                  await appState.deleteTask(schedule.id);
                } else if (schedule.type == ScheduleType.communityMeal) {
                  await appState.deleteMeal(schedule.id);
                } else {
                  await appState.deleteSchedule(schedule.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted: ${schedule.title}')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<Schedule> allDisplayableItems = [
      ...appState.schedules.where((s) => s.type != ScheduleType.task && s.type != ScheduleType.communityMeal), // General schedules
      ...appState.managedTasks,    // Tasks
      ...appState.communityMeals, // Community Meals
    ];
    allDisplayableItems.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (allDisplayableItems.isEmpty) {
      return const EmptyStateView(
        icon: Icons.calendar_today_rounded,
        message: 'No scheduled events, tasks, or meals',
      );
    }

    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalendarView(schedules: allDisplayableItems.where((s) => s.type != ScheduleType.task && s.type != ScheduleType.communityMeal).toList()), // Only pass general schedules to calendar view
          const SizedBox(height: 16),
          Text(
            'Upcoming Items', // Changed from 'Upcoming Events'
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allDisplayableItems.length,
            itemBuilder: (context, index) {
              final item = allDisplayableItems[index];
              return _ScheduleCard(
                schedule: item,
                appState: appState,
                onEdit: () => _editScheduleWrapper(context, item),
                onDelete: () => _deleteScheduleWrapper(context, item),
                getUserName: getUserName,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget { // This remains largely unchanged, displays general schedules
  final List<Schedule> schedules;
  const _CalendarView({required this.schedules});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(today),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { /* Previous month */ }),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { /* Next month */ }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200, // Placeholder for actual calendar grid
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('Calendar View (General Schedules)', style: theme.textTheme.titleMedium)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final AppStateProvider appState;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(String userId, AppStateProvider appState) getUserName;

  const _ScheduleCard({
    required this.schedule,
    required this.appState,
    required this.onEdit,
    required this.onDelete,
    required this.getUserName,
  });

  IconData _getScheduleIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.laundry: return Icons.local_laundry_service_rounded;
      case ScheduleType.cleaning: return Icons.cleaning_services_rounded;
      case ScheduleType.cooking: return Icons.restaurant_rounded;
      case ScheduleType.task: return schedule.isCompleted ? Icons.task_alt_rounded : Icons.assignment_late_rounded;
      case ScheduleType.communityMeal: return Icons.dinner_dining_rounded;
      case ScheduleType.other:
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = appState.currentUser;

    Widget? specialActionWidget;
    List<Widget> subtitleChildren = [
      const SizedBox(height: 4),
      Row(
        children: [
          Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(schedule.getFormattedTimeRange(), style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(schedule.getFormattedDate(), style: theme.textTheme.bodySmall),
        ],
      ),
    ];

    if (schedule.description.isNotEmpty) {
      subtitleChildren.add(const SizedBox(height: 4));
      subtitleChildren.add(Text(schedule.description, style: theme.textTheme.bodySmall));
    }

    if (schedule.type == ScheduleType.task) {
      subtitleChildren.add(const SizedBox(height: 4));
      String assignedText = "Assigned: ";
      if (schedule.assignedUserIds.isEmpty) {
        assignedText += "None";
      } else {
        assignedText += schedule.assignedUserIds.map((id) => getUserName(id, appState)).join(', ');
      }
      subtitleChildren.add(Text(assignedText, style: theme.textTheme.bodySmall));

      if (currentUser != null && schedule.assignedUserIds.contains(currentUser.id) && !schedule.isCompleted) {
        specialActionWidget = Checkbox(
          value: schedule.isCompleted,
          onChanged: (bool? newValue) async {
            if (newValue == true) {
              try {
                await appState.markTaskCompleted(schedule.id, currentUser.id);
                // Placeholder for checkmark explosion animation
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task "${schedule.title}" marked complete!')));
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
        );
      } else if (schedule.isCompleted) {
         subtitleChildren.add(Text("Status: Completed", style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontStyle: FontStyle.italic)));
      }
    } else if (schedule.type == ScheduleType.communityMeal && currentUser != null) {
      subtitleChildren.add(const SizedBox(height: 4));
      subtitleChildren.add(Text("Opted-in: ${schedule.optedInUserIds.length} users", style: theme.textTheme.bodySmall));
      specialActionWidget = Switch(
        value: schedule.optedInUserIds.contains(currentUser.id),
        onChanged: (bool newValue) async {
          try {
            if (newValue) {
              await appState.optInToMeal(schedule.id, currentUser.id);
            } else {
              await appState.optOutOfMeal(schedule.id, currentUser.id);
            }
            // Placeholder for fade-in animation for menu updates (would be on list, not switch itself)
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: schedule.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getScheduleIcon(schedule.type), color: schedule.color),
        ),
        title: Text(
          schedule.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: schedule.type == ScheduleType.task && schedule.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subtitleChildren,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (specialActionWidget != null) specialActionWidget,
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _LaundryTab extends StatelessWidget {
  final AppStateProvider appState;
  final String Function(String userId, AppStateProvider appState) getUserName;
  const _LaundryTab({required this.appState, required this.getUserName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = appState.currentUser;

    // For simplicity, hardcoding days. A real app might generate this or use a calendar.
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard( // Assuming CustomCard exists
            title: 'Laundry Schedule',
            titleIcon: Icons.local_laundry_service_rounded,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text('Book your laundry time slots. Limit: 2 per week.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                if (appState.laundrySlots.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No laundry slots defined yet.")))
                else
                  _LaundryScheduleGrid(
                    daysOfWeek: daysOfWeek, // This is simplified, laundry slots are not tied to specific days in current model
                    timeSlots: appState.laundrySlots,
                    appState: appState,
                    currentUser: currentUser,
                    getUserName: getUserName,
                  ),
                const SizedBox(height: 16),
                // Removed general "Book Slot" button, booking is on grid.
                // UI for swap requests and admin approval would be more complex.
                // For now, a placeholder for swap idea:
                TextButton(
                    onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot swap UI not yet implemented.")));
                        // Dialog to pick slot to give up, slot to take. Then call appState.requestLaundrySlotSwap()
                    },
                    child: Text("Request Slot Swap (Placeholder)")
                )

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LaundryScheduleGrid extends StatelessWidget {
  final List<String> daysOfWeek; // Simplified, not used for filtering slots directly
  final List<TimeSlot> timeSlots;
  final AppStateProvider appState;
  final User? currentUser;
  final String Function(String userId, AppStateProvider appState) getUserName;

  const _LaundryScheduleGrid({
    required this.daysOfWeek,
    required this.timeSlots,
    required this.appState,
    required this.currentUser,
    required this.getUserName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group slots by a conceptual day if needed, or just list them.
    // The current TimeSlot model doesn't have a date, only TimeOfDay.
    // For this grid, we'll just list all available slots.
    // A real implementation would need slots associated with specific dates.
    // We'll display slots and assume they are for "today" or a generic template.

    if (timeSlots.isEmpty) {
      return const Text("No time slots available.");
    }

    return Column( // Changed from DataTable for simplicity as slots aren't per day yet
      children: timeSlots.map((slot) {
        bool isBookedByCurrentUser = slot.userId == currentUser?.id;
        bool canBook = appState.canBookLaundrySlot(currentUser?.id ?? "");

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(slot.getFormattedTimeRange()),
            subtitle: slot.isAvailable
                ? const Text("Available", style: TextStyle(color: Colors.green))
                : Text("Booked by: ${slot.userId != null ? getUserName(slot.userId!, appState) : 'Unknown'}", style: TextStyle(color: Colors.orange)),
            trailing: slot.isAvailable
                ? ElevatedButton(
                    child: const Text("Book"),
                    onPressed: (currentUser != null && canBook)
                        ? () async {
                            try {
                                await appState.bookLaundrySlot(slot.id, currentUser.id);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot booked!")));
                            } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          }
                        : null, // Disabled if no user or cannot book
                  )
                : isBookedByCurrentUser
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text("Cancel"),
                        onPressed: () async {
                           try {
                                await appState.cancelLaundrySlot(slot.id, currentUser!.id);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking cancelled.")));
                            } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                        },
                      )
                    : null, // Not available, not booked by current user
            tileColor: slot.adminApproved && !slot.isAvailable ? Colors.teal.withOpacity(0.1) : null, // Indicate admin approved swap
            leading: Icon(slot.isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined, color: slot.isAvailable ? Colors.green : Colors.red ),
          ),
        );
      }).toList(),
    );
  }
}


class _AddScheduleForm extends StatefulWidget {
  final AppStateProvider appState;
  final Schedule? existingSchedule;
  final String Function(String userId, AppStateProvider appState) getUserName;


  const _AddScheduleForm({
    required this.appState,
    this.existingSchedule,
    required this.getUserName,
  });

  @override
  State<_AddScheduleForm> createState() => _AddScheduleFormState();
}

class _AddScheduleFormState extends State<_AddScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late ScheduleType _scheduleType;
  late bool _isRecurring;
  late RecurrenceFrequency _recurrenceFrequency;
  late int _recurrenceInterval;
  late Color _selectedColor;
  List<String> _selectedAssignedUserIds = [];

  @override
  void initState() {
    super.initState();
    final schedule = widget.existingSchedule;
    if (schedule != null) {
      _titleController = TextEditingController(text: schedule.title);
      _descriptionController = TextEditingController(text: schedule.description);
      _startDate = schedule.startTime;
      _startTime = TimeOfDay.fromDateTime(schedule.startTime);
      _endDate = schedule.endTime;
      _endTime = TimeOfDay.fromDateTime(schedule.endTime);
      _scheduleType = schedule.type;
      _isRecurring = schedule.isRecurring;
      _selectedColor = schedule.color;
      _selectedAssignedUserIds = List<String>.from(schedule.assignedUserIds); // Initialize for tasks
      // optedInUserIds for meals are managed directly on the card, not typically in the creation form.
      if (schedule.recurrence != null) {
        _recurrenceFrequency = schedule.recurrence!.frequency;
        _recurrenceInterval = schedule.recurrence!.interval;
      } else {
        _recurrenceFrequency = RecurrenceFrequency.weekly;
        _recurrenceInterval = 1;
      }
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endDate = DateTime.now().add(const Duration(hours: 1));
      _endTime = TimeOfDay.fromDateTime(_endDate);
      _scheduleType = ScheduleType.other; // Default to 'other' or 'task'
      _isRecurring = false;
      _recurrenceFrequency = RecurrenceFrequency.weekly;
      _recurrenceInterval = 1;
      _selectedColor = Colors.blue; // Default color
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final initialTime = isStart ? _startTime : _endTime;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow past for editing
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: initialTime);
    if (time == null) return;

    setState(() {
      if (isStart) {
        _startDate = date;
        _startTime = time;
        // Ensure end time is after start time
        final startDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (_endDate.isBefore(startDateTime) || (_endDate.isAtSameMomentAs(startDateTime) && _endTime.hour * 60 + _endTime.minute <= time.hour*60 + time.minute)) {
            _endDate = startDateTime.add(const Duration(hours:1)); // Default to 1 hour duration
            _endTime = TimeOfDay.fromDateTime(_endDate);
        }

      } else {
        _endDate = date;
        _endTime = time;
      }
    });
  }
  
  void _showUserSelectionDialog() {
    final allUsers = widget.appState.users;
    showDialog(
        context: context,
        builder: (context) {
            List<String> tempSelectedUserIds = List.from(_selectedAssignedUserIds); // Temporary list for dialog state
            return StatefulBuilder( // Use StatefulBuilder to manage dialog's own state
                builder: (context, setDialogState) {
                    return AlertDialog(
                        title: Text("Assign Users"),
                        content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: allUsers.length,
                                itemBuilder: (context, index) {
                                    final user = allUsers[index];
                                    return CheckboxListTile(
                                        title: Text(user.name),
                                        value: tempSelectedUserIds.contains(user.id),
                                        onChanged: (bool? selected) {
                                            setDialogState(() {
                                                if (selected == true) {
                                                    tempSelectedUserIds.add(user.id);
                                                } else {
                                                    tempSelectedUserIds.remove(user.id);
                                                }
                                            });
                                        },
                                    );
                                },
                            ),
                        ),
                        actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                            TextButton(
                                onPressed: () {
                                    setState(() { // Update the main form's state
                                        _selectedAssignedUserIds = List.from(tempSelectedUserIds);
                                    });
                                    Navigator.pop(context);
                                },
                                child: Text("OK")),
                        ],
                    );
                },
            );
        });
}


  void _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("End time cannot be before start time.")));
      return;
    }

    RecurrencePattern? recurrence;
    if (_isRecurring) {
      recurrence = RecurrencePattern(
        frequency: _recurrenceFrequency,
        interval: _recurrenceInterval,
        // daysOfWeek would need UI if we want to support it
      );
    }

    final schedule = Schedule(
      id: widget.existingSchedule?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      type: _scheduleType,
      userId: widget.appState.currentUser?.id ?? 'unknown_user', // Creator
      isRecurring: _isRecurring,
      recurrence: recurrence,
      color: _selectedColor,
      assignedUserIds: _scheduleType == ScheduleType.task ? _selectedAssignedUserIds : [],
      optedInUserIds: widget.existingSchedule?.optedInUserIds ?? [], // Preserve existing opt-ins for meals if editing
      isCompleted: widget.existingSchedule?.isCompleted ?? false, // Preserve existing completion status
    );

    // Conflict check (optional, can be refined)
    // if (widget.appState.hasScheduleConflict(schedule, widget.existingSchedule?.id)) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This schedule conflicts with an existing one.')));
    //   return;
    // }

    try {
      if (widget.existingSchedule == null) { // New schedule
        switch (_scheduleType) {
          case ScheduleType.task: await widget.appState.addTask(schedule); break;
          case ScheduleType.communityMeal: await widget.appState.addMeal(schedule); break;
          default: await widget.appState.addSchedule(schedule); break;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added: ${schedule.title}')));
      } else { // Existing schedule
        switch (_scheduleType) {
          case ScheduleType.task: await widget.appState.updateTask(schedule); break;
          case ScheduleType.communityMeal: await widget.appState.updateMeal(schedule); break;
          default: await widget.appState.updateSchedule(schedule); break;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated: ${schedule.title}')));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), // Adjust padding for keyboard
      child: Form(
        key: _formKey,
        child: ListView( // Changed to ListView to prevent overflow
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.existingSchedule == null ? 'Add New Item' : 'Edit Item', style: theme.textTheme.headlineSmall),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.title_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.description_rounded)),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ScheduleType>(
              decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.category_rounded)),
              value: _scheduleType,
              items: ScheduleType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.toString().split('.').last))).toList(),
              onChanged: (v) => setState(() => _scheduleType = v!),
            ),
            
            if (_scheduleType == ScheduleType.task) ...[
                const SizedBox(height: 16),
                ListTile(
                    title: Text("Assigned Users: ${_selectedAssignedUserIds.map((id) => widget.getUserName(id, widget.appState)).join(', ')}"),
                    trailing: IconButton(icon: Icon(Icons.group_add_rounded), onPressed: _showUserSelectionDialog),
                    contentPadding: EdgeInsets.zero,
                ),
            ],
             if (_scheduleType == ScheduleType.communityMeal) ...[
                const SizedBox(height: 16),
                // Specific fields for meals can be added here, e.g., menu items as part of description or a new field.
                // For now, description field can be used for menu.
                Text("Meal specific options can be added here.", style: theme.textTheme.caption),
            ],


            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ListTile(title: const Text('Start'), subtitle: Text('${DateFormat('MM/dd/yyyy').format(_startDate)} ${MaterialLocalizations.of(context).formatTimeOfDay(_startTime)}'), trailing: IconButton(icon: const Icon(Icons.edit_calendar_rounded), onPressed: () => _pickDateTime(true)))),
              Expanded(child: ListTile(title: const Text('End'), subtitle: Text('${DateFormat('MM/dd/yyyy').format(_endDate)} ${MaterialLocalizations.of(context).formatTimeOfDay(_endTime)}'), trailing: IconButton(icon: const Icon(Icons.edit_calendar_rounded), onPressed: () => _pickDateTime(false)))),
            ]),
            const SizedBox(height: 16),
            SwitchListTile(title: const Text('Recurring'), value: _isRecurring, onChanged: (v) => setState(() => _isRecurring = v)),
            if (_isRecurring) ...[
              DropdownButtonFormField<RecurrenceFrequency>(
                decoration: InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                value: _recurrenceFrequency,
                items: RecurrenceFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.toString().split('.').last))).toList(),
                onChanged: (v) => setState(() => _recurrenceFrequency = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _recurrenceInterval.toString(),
                decoration: InputDecoration(labelText: 'Interval (e.g., every 1 week)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
                onChanged: (v) => _recurrenceInterval = int.tryParse(v) ?? 1,
              ),
            ],
            const SizedBox(height: 16),
            Text('Color', style: theme.textTheme.titleMedium),
            Wrap(spacing: 8, children: [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal]
                .map((c) => GestureDetector(onTap: () => setState(() => _selectedColor = c), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _selectedColor == c ? theme.colorScheme.primary : Colors.transparent, width: 3)))))
                .toList()),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(widget.existingSchedule == null ? 'Add Item' : 'Update Item'),
            ),
            const SizedBox(height: 24), // Padding for keyboard
          ],
        ),
      ),
    );
  }
}
