import 'package:flutter/material.dart';

enum ScheduleStatus {
  pending,
  completed,
  rescheduled,
  skipped,
  absent,
}

class ScheduleItem {
  final String id;
  final DateTime originalDate;
  DateTime currentDate;
  final List<Map<String, dynamic>> verses;
  ScheduleStatus status;
  String? notes;
  String? rescheduleReason;
  DateTime? completionDate;
  String? skipReason;
  int rating;  // 0-5 stars
  bool isAbsent;
  List<Map<String, dynamic>> rescheduleHistory;

  ScheduleItem({
    required this.id,
    required this.originalDate,
    required this.currentDate,
    required this.verses,
    this.status = ScheduleStatus.pending,
    this.notes,
    this.rescheduleReason,
    this.completionDate,
    this.skipReason,
    this.rating = 0,
    this.isAbsent = false,
    List<Map<String, dynamic>>? rescheduleHistory,
  }) : rescheduleHistory = rescheduleHistory ?? [];

  // Method to reschedule this item
  void reschedule(DateTime newDate, {String? reason}) {
    currentDate = newDate;
    status = ScheduleStatus.rescheduled;
    rescheduleReason = reason;
  }

  // Method to mark as completed
  void markAsCompleted() {
    status = ScheduleStatus.completed;
    completionDate = DateTime.now();
  }

  // Method to mark as skipped
  void markAsSkipped({String? reason}) {
    status = ScheduleStatus.skipped;
    skipReason = reason;
  }

  // Method to mark as rescheduled
  void markAsRescheduled({String? reason}) {
    status = ScheduleStatus.rescheduled;
    rescheduleReason = reason;
  }

  // Method to set rating
  void setRating(int newRating) {
    rating = newRating.clamp(0, 5);
  }

  // Method to set attendance
  void setAttendance(bool absent) {
    isAbsent = absent;
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalDate': originalDate.toIso8601String(),
      'currentDate': currentDate.toIso8601String(),
      'verses': verses,
      'status': status.toString(),
      'notes': notes,
      'rescheduleReason': rescheduleReason,
      'completionDate': completionDate?.toIso8601String(),
      'skipReason': skipReason,
      'rating': rating,
      'isAbsent': isAbsent,
      'rescheduleHistory': rescheduleHistory,
    };
  }

  // Create from map (for database retrieval)
  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'],
      originalDate: DateTime.parse(map['originalDate']),
      currentDate: DateTime.parse(map['currentDate']),
      verses: List<Map<String, dynamic>>.from(map['verses']),
      status: ScheduleStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ScheduleStatus.pending,
      ),
      notes: map['notes'],
      rescheduleReason: map['rescheduleReason'],
      completionDate: map['completionDate'] != null 
          ? DateTime.parse(map['completionDate']) 
          : null,
      skipReason: map['skipReason'],
      rating: map['rating'] ?? 0,
      isAbsent: map['isAbsent'] ?? false,
      rescheduleHistory: List<Map<String, dynamic>>.from(map['rescheduleHistory']),
    );
  }

  Color getStatusColor() {
    switch (status) {
      case ScheduleStatus.pending:
        return Colors.blue;
      case ScheduleStatus.completed:
        return Colors.green;
      case ScheduleStatus.rescheduled:
        return Colors.orange;
      case ScheduleStatus.skipped:
        return Colors.red;
      case ScheduleStatus.absent:
        return Colors.grey;
    }
  }

  String getStatusText() {
    switch (status) {
      case ScheduleStatus.pending:
        return 'معلق';
      case ScheduleStatus.completed:
        return 'مكتمل';
      case ScheduleStatus.rescheduled:
        return 'مؤجل';
      case ScheduleStatus.skipped:
        return 'متخطي';
      case ScheduleStatus.absent:
        return 'غياب';
    }
  }


  ScheduleItem copyWith({
  String? id,
  DateTime? originalDate,
  DateTime? currentDate,
  List<Map<String, dynamic>>? verses,
  ScheduleStatus? status,
  String? rescheduleReason,
  String? skipReason,
  DateTime? completionDate,
}) {
  return ScheduleItem(
    id: id ?? this.id,
    originalDate: originalDate ?? this.originalDate,
    currentDate: currentDate ?? this.currentDate,
    verses: verses ?? List.from(this.verses),
    status: status ?? this.status,
    rescheduleReason: rescheduleReason ?? this.rescheduleReason,
    skipReason: skipReason ?? this.skipReason,
    completionDate: completionDate ?? this.completionDate,
  );
}
} 