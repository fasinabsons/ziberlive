import 'package:flutter/material.dart';

enum ScheduleType {
  laundry,
  cleaning,
  cooking,
  task,
  communityMeal,
  other,
}

class Schedule {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleType type;
  final String userId;
  final bool isRecurring;
  final RecurrencePattern? recurrence;
  final Color color;

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
      'color': color.toARGB32(),
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
      color: Color(json['color']),
    );
  }

  static ScheduleType _parseScheduleType(String type) {
    if (type.contains('laundry')) return ScheduleType.laundry;
    if (type.contains('cleaning')) return ScheduleType.cleaning;
    if (type.contains('cooking')) return ScheduleType.cooking;
    return ScheduleType.other;
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
    final start = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  // Get formatted date
  String getFormattedDate() {
    return '${startTime.month}/${startTime.day}/${startTime.year}';
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

  static RecurrenceFrequency _parseRecurrenceFrequency(String frequency) {
    if (frequency.contains('daily')) return RecurrenceFrequency.daily;
    if (frequency.contains('weekly')) return RecurrenceFrequency.weekly;
    return RecurrenceFrequency.monthly;
  }

  // Get next occurrence after a given date
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
          next = DateTime(next.year, next.month + interval, next.day);
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
  final String? userId;
  final bool isAvailable;

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.userId,
    this.isAvailable = true,
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
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      startTime: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
      endTime: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
      userId: json['userId'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  // Get formatted time range
  String getFormattedTimeRange() {
    final start = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
} 
