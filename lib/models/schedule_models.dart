import 'package:flutter/material.dart';

enum ScheduleType {
  laundry,
  cleaning,
  cooking,
  task, // New
  communityMeal, // New
  other,
}

class Schedule {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleType type;
  final String userId; // Creator or primary user for the schedule
  final bool isRecurring;
  final RecurrencePattern? recurrence;
  final Color color;
  final List<String> assignedUserIds; // For tasks
  final List<String> optedInUserIds;  // For community meals
  final bool isCompleted;             // For tasks

  const Schedule({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.userId,
    this.isRecurring = false,
    this.recurrence,
    required this.color,
    this.assignedUserIds = const [], // Default to empty list
    this.optedInUserIds = const [],  // Default to empty list
    this.isCompleted = false,       // Default to false
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.toString(),
      'userId': userId,
      'isRecurring': isRecurring,
      'recurrence': recurrence?.toJson(),
      'color': color.value, // Changed to .value for consistency (ARGB int)
      'assignedUserIds': assignedUserIds,
      'optedInUserIds': optedInUserIds,
      'isCompleted': isCompleted,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: _parseScheduleType(json['type']),
      userId: json['userId'],
      isRecurring: json['isRecurring'] ?? false,
      recurrence: json['recurrence'] != null
          ? RecurrencePattern.fromJson(json['recurrence'])
          : null,
      // Ensure color is parsed correctly, it might be stored as int
      color: Color(json['color'] ?? Colors.blue.value), // Default if null
      assignedUserIds: List<String>.from(json['assignedUserIds'] ?? []),
      optedInUserIds: List<String>.from(json['optedInUserIds'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  static ScheduleType _parseScheduleType(String typeString) {
    // More robust parsing based on the full enum string e.g., "ScheduleType.task"
    if (typeString == ScheduleType.task.toString()) return ScheduleType.task;
    if (typeString == ScheduleType.communityMeal.toString()) return ScheduleType.communityMeal;
    if (typeString == ScheduleType.laundry.toString()) return ScheduleType.laundry;
    if (typeString == ScheduleType.cleaning.toString()) return ScheduleType.cleaning;
    if (typeString == ScheduleType.cooking.toString()) return ScheduleType.cooking;
    if (typeString == ScheduleType.other.toString()) return ScheduleType.other;

    // Fallback for older data that might just contain the word
    if (typeString.contains('task')) return ScheduleType.task;
    if (typeString.contains('communityMeal')) return ScheduleType.communityMeal;
    if (typeString.contains('laundry')) return ScheduleType.laundry;
    if (typeString.contains('cleaning')) return ScheduleType.cleaning;
    if (typeString.contains('cooking')) return ScheduleType.cooking;
    return ScheduleType.other; // Default fallback
  }

  // Get duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // Check if schedule overlaps with another schedule
  bool overlaps(Schedule other) {
    return (startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime));
  }

  // Get formatted time range
  String getFormattedTimeRange() {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  // Get formatted date
  String getFormattedDate() {
    final month = startTime.month.toString().padLeft(2, '0');
    final day = startTime.day.toString().padLeft(2, '0');
    return '$month/$day/${startTime.year}';
  }
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
}

class RecurrencePattern {
  final RecurrenceFrequency frequency;
  final int interval;
  final List<int> daysOfWeek; // 1-7 for Monday-Sunday
  final DateTime? endDate;
  final int? occurrences;

  const RecurrencePattern({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.endDate,
    this.occurrences,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.toString(),
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      frequency: _parseRecurrenceFrequency(json['frequency']),
      interval: json['interval'] ?? 1,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : [],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      occurrences: json['occurrences'],
    );
  }

  static RecurrenceFrequency _parseRecurrenceFrequency(String typeString) {
    if (typeString == RecurrenceFrequency.daily.toString()) return RecurrenceFrequency.daily;
    if (typeString == RecurrenceFrequency.weekly.toString()) return RecurrenceFrequency.weekly;
    if (typeString == RecurrenceFrequency.monthly.toString()) return RecurrenceFrequency.monthly;
    
    // Fallback for older data
    if (typeString.contains('daily')) return RecurrenceFrequency.daily;
    if (typeString.contains('weekly')) return RecurrenceFrequency.weekly;
    return RecurrenceFrequency.monthly;
  }

  DateTime getNextOccurrence(DateTime after, DateTime originalStart) {
    DateTime next = originalStart;
    
    while (!next.isAfter(after)) {
      switch (frequency) {
        case RecurrenceFrequency.daily:
          next = next.add(Duration(days: interval));
          break;
        case RecurrenceFrequency.weekly:
          next = next.add(Duration(days: 7 * interval));
          break;
        case RecurrenceFrequency.monthly:
          // This logic for monthly recurrence might need to be more robust
          // to handle end of month cases correctly (e.g., Jan 31st + 1 month != Feb 31st)
          var newMonth = next.month + interval;
          var newYear = next.year;
          if (newMonth > 12) {
            newYear += (newMonth -1) ~/ 12;
            newMonth = (newMonth - 1) % 12 + 1;
          }
          // Check if the day exists in the new month, otherwise go to last day of new month
          var newDay = next.day;
          var daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
          if (newDay > daysInNewMonth) {
            newDay = daysInNewMonth;
          }
          next = DateTime(newYear, newMonth, newDay, next.hour, next.minute, next.second, next.millisecond, next.microsecond);
          break;
      }
    }
    return next;
  }
}

// TimeSlot model for laundry scheduling
class TimeSlot {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? userId; // User who booked the slot
  final bool isAvailable;
  final bool adminApproved; // For slot swaps

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.isAvailable = true,
    this.adminApproved = false, // Default to false
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'userId': userId,
      'isAvailable': isAvailable,
      'adminApproved': adminApproved,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      startTime: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
      endTime: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
      userId: json['userId'],
      isAvailable: json['isAvailable'] ?? true,
      adminApproved: json['adminApproved'] ?? false,
    );
  }

  String getFormattedTimeRange() {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }
}
