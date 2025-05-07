import 'package:hafiz_quran/models/schedule_item.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' as intl;
class ScheduleService {
  final List<ScheduleItem> _scheduleItems = [];
  final _ulid = Uuid();
  List<String> _recitationDays = [];

  // Initialize schedule with items
  void initializeSchedule(List<Map<String, dynamic>> schedule, List<String> recitationDays) {
    _recitationDays = recitationDays;
    _scheduleItems.clear();
    for (var item in schedule) {
      _scheduleItems.add(ScheduleItem(
        id: _ulid.v4(),
        originalDate: item['date'],
        currentDate: item['date'],
        verses: item['verses'],
      ));
    }
  }

  List<String> getRecitationDayss() => _recitationDays;
  // Get all schedule items
  List<ScheduleItem> getAllItems() => _scheduleItems;

  // Get items by status
  List<ScheduleItem> getItemsByStatus(ScheduleStatus status) =>
      _scheduleItems.where((item) => item.status == status).toList();

///TODO: Reschedule an item and handle cascading effects
  // Reschedule an item and handle cascading effects
  void rescheduleItem(String itemId, DateTime newDate, {String? reason}) {
    final itemToReschedule = _scheduleItems.firstWhere((i) => i.id == itemId);
    final rescheduleIndex = _scheduleItems.indexOf(itemToReschedule);
    
    // Add new empty item at the end with next available recitation day
    DateTime nextDate = _scheduleItems.last.currentDate;
    do {
      nextDate = nextDate.add(const Duration(days: 1));
    } while (!_recitationDays.contains(intl.DateFormat('EEEE').format(nextDate)));
    
    _scheduleItems.add(ScheduleItem(
      id: _ulid.v4(),
      originalDate: nextDate,
      currentDate: nextDate,
      verses: [],
    ));
    
    // Copy data from each item to the next one, starting from the end
    for(int i = _scheduleItems.length - 1; i > rescheduleIndex; i--) {
      _scheduleItems[i] = _scheduleItems[i].copyWith(
        verses: List.from(_scheduleItems[i - 1].verses)
      );
    }
    
    itemToReschedule.markAsRescheduled(reason: reason);
  }

  // Mark an item as completed
  void markAsCompleted(String itemId) {
    final item = _scheduleItems.firstWhere((i) => i.id == itemId);
    item.markAsCompleted();
  }

  // Mark an item as skipped
  void markAsSkipped(String itemId, {String? reason}) {
    final item = _scheduleItems.firstWhere((i) => i.id == itemId);
    item.markAsSkipped(reason: reason);
  }

  // Get schedule statistics
  Map<String, dynamic> getStatistics() {
    final total = _scheduleItems.length;
    final completed = _scheduleItems.where((i) => i.status == ScheduleStatus.completed).length;
    final pending = _scheduleItems.where((i) => i.status == ScheduleStatus.pending).length;
    final rescheduled = _scheduleItems.where((i) => i.status == ScheduleStatus.rescheduled).length;
    final skipped = _scheduleItems.where((i) => i.status == ScheduleStatus.skipped).length;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'rescheduled': rescheduled,
      'skipped': skipped,
      'completionPercentage': (completed / total * 100).toStringAsFixed(1),
    };
  }



} 


