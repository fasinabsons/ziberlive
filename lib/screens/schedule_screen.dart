import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../models/schedule_models.dart';
import '../widgets/custom_widget.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar'),
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
          _CalendarTab(schedules: appState.schedules),
          const _LaundryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context, appState),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        heroTag: 'add_schedule',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
  
  void _showAddScheduleDialog(BuildContext context, AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => _AddScheduleForm(appState: appState),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  final List<Schedule> schedules;
  
  const _CalendarTab({required this.schedules});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    
    if (schedules.isEmpty) {
      return const EmptyStateView(
        icon: Icons.calendar_today_rounded,
        message: 'No scheduled events',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalendarView(schedules: schedules),
          const SizedBox(height: 16),
          Text(
            'Upcoming Events',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _ScheduleCard(
                schedule: schedule,
                onEdit: () => _editSchedule(context, appState, schedule),
                onDelete: () => _deleteSchedule(context, appState, schedule),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _editSchedule(BuildContext context, AppStateProvider appState, Schedule schedule) {
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
          existingSchedule: schedule,
        ),
      ),
    );
  }
  
  void _deleteSchedule(BuildContext context, AppStateProvider appState, Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.deleteSchedule(schedule.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted: ${schedule.title}')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        // Previous month
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        // Next month
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Calendar grid would go here
            // This is a simplified placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Calendar View',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
          child: Icon(
            _getScheduleIcon(schedule.type),
            color: schedule.color,
          ),
        ),
        title: Text(
          schedule.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.getFormattedTimeRange(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.getFormattedDate(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (schedule.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                schedule.description,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getScheduleIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.laundry:
        return Icons.local_laundry_service_rounded;
      case ScheduleType.cleaning:
        return Icons.cleaning_services_rounded;
      case ScheduleType.cooking:
        return Icons.restaurant_rounded;
      case ScheduleType.other:
        return Icons.event_rounded;
    }
  }
}

class _LaundryTab extends StatelessWidget {
  const _LaundryTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Mock data - would come from AppStateProvider
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final timeSlots = [
      TimeSlot(id: '1', startTime: const TimeOfDay(hour: 8, minute: 0), endTime: const TimeOfDay(hour: 10, minute: 0)),
      TimeSlot(id: '2', startTime: const TimeOfDay(hour: 10, minute: 0), endTime: const TimeOfDay(hour: 12, minute: 0)),
      TimeSlot(id: '3', startTime: const TimeOfDay(hour: 12, minute: 0), endTime: const TimeOfDay(hour: 14, minute: 0)),
      TimeSlot(id: '4', startTime: const TimeOfDay(hour: 14, minute: 0), endTime: const TimeOfDay(hour: 16, minute: 0)),
      TimeSlot(id: '5', startTime: const TimeOfDay(hour: 16, minute: 0), endTime: const TimeOfDay(hour: 18, minute: 0)),
      TimeSlot(id: '6', startTime: const TimeOfDay(hour: 18, minute: 0), endTime: const TimeOfDay(hour: 20, minute: 0)),
    ];
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh data
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            title: 'Laundry Schedule',
            titleIcon: Icons.local_laundry_service_rounded,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'Book your laundry time slots',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _LaundryScheduleGrid(daysOfWeek: daysOfWeek, timeSlots: timeSlots),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Book laundry slot
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Book Slot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LaundryScheduleGrid extends StatelessWidget {
  final List<String> daysOfWeek;
  final List<TimeSlot> timeSlots;
  
  const _LaundryScheduleGrid({
    required this.daysOfWeek,
    required this.timeSlots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(theme.colorScheme.primary.withOpacity(0.1)),
        dataRowColor: WidgetStateProperty.all(Colors.transparent),
        columns: [
          const DataColumn(label: Text('Time')),
          ...daysOfWeek.map((day) => DataColumn(label: Text(day))),
        ],
        rows: timeSlots.map((slot) {
          return DataRow(
            cells: [
              DataCell(Text(slot.getFormattedTimeRange())),
              ...daysOfWeek.map((day) {
                // Check if slot is booked for this day
                final isBooked = false; // This would come from data
                return DataCell(
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isBooked ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBooked ? Icons.close : Icons.check,
                      size: 16,
                      color: isBooked ? Colors.red : Colors.green,
                    ),
                  ),
                  onTap: () {
                    // Toggle booking
                  },
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AddScheduleForm extends StatefulWidget {
  final AppStateProvider appState;
  final Schedule? existingSchedule;

  const _AddScheduleForm({
    required this.appState,
    this.existingSchedule,
  });

  @override
  State<_AddScheduleForm> createState() => _AddScheduleFormState();
}

class _AddScheduleFormState extends State<_AddScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  ScheduleType _scheduleType = ScheduleType.other;
  bool _isRecurring = false;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.weekly;
  int _recurrenceInterval = 1;
  Color _selectedColor = Colors.blue;
  
  @override
  void initState() {
    super.initState();
    
    // If editing an existing schedule, initialize form with its data
    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _titleController.text = schedule.title;
      _descriptionController.text = schedule.description;
      _startDate = schedule.startTime;
      _startTime = TimeOfDay.fromDateTime(schedule.startTime);
      _endDate = schedule.endTime;
      _endTime = TimeOfDay.fromDateTime(schedule.endTime);
      _scheduleType = schedule.type;
      _isRecurring = schedule.isRecurring;
      _selectedColor = schedule.color;
      
      if (schedule.recurrence != null) {
        _recurrenceFrequency = schedule.recurrence!.frequency;
        _recurrenceInterval = schedule.recurrence!.interval;
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingSchedule == null ? 'Add New Schedule' : 'Edit Schedule',
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description_rounded),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ScheduleType>(
              decoration: InputDecoration(
                labelText: 'Schedule Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category_rounded),
              ),
              value: _scheduleType,
              items: ScheduleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _scheduleType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start'),
                    subtitle: Text(
                      '${DateFormat('MM/dd/yyyy').format(_startDate)} ${_startTime.format(context)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded),
                      onPressed: () async {
                        // Pick start date and time
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                        
                        if (context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) {
                            setState(() {
                              _startTime = time;
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End'),
                    subtitle: Text(
                      '${DateFormat('MM/dd/yyyy').format(_endDate)} ${_endTime.format(context)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded),
                      onPressed: () async {
                        // Pick end date and time
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                        
                        if (context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (time != null) {
                            setState(() {
                              _endTime = time;
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring Schedule'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurrenceFrequency>(
                decoration: InputDecoration(
                  labelText: 'Recurrence',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _recurrenceFrequency,
                items: RecurrenceFrequency.values.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _recurrenceFrequency = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Every ', style: theme.textTheme.titleSmall),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue: _recurrenceInterval.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _recurrenceInterval = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _recurrenceFrequency == RecurrenceFrequency.daily
                        ? 'day(s)'
                        : _recurrenceFrequency == RecurrenceFrequency.weekly
                            ? 'week(s)'
                            : 'month(s)',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Color',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.red,
                Colors.teal,
              ].map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(widget.existingSchedule == null ? 'Add Schedule' : 'Update Schedule'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      // Create DateTime objects from date and time
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      // Create recurrence pattern if needed
      RecurrencePattern? recurrence;
      if (_isRecurring) {
        recurrence = RecurrencePattern(
          frequency: _recurrenceFrequency,
          interval: _recurrenceInterval,
        );
      }
      
      // Create schedule
      final schedule = Schedule(
        id: widget.existingSchedule?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        type: _scheduleType,
        userId: widget.appState.currentUser?.id ?? 'unknown_user',
        isRecurring: _isRecurring,
        recurrence: recurrence,
        color: _selectedColor,
      );
      
      // Check for conflicts
      if (widget.appState.hasScheduleConflict(schedule, widget.existingSchedule?.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This schedule conflicts with an existing one. Please choose a different time.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Save schedule to provider
      if (widget.existingSchedule == null) {
        widget.appState.addSchedule(schedule);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added schedule: ${schedule.title}')),
        );
      } else {
        widget.appState.updateSchedule(schedule);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated schedule: ${schedule.title}')),
        );
      }
      
      // Close form
      Navigator.pop(context);
    }
  }
} 