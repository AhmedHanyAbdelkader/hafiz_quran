import 'package:flutter/material.dart';
import 'package:hafiz_quran/services/schedule_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:data_table_2/data_table_2.dart';
import 'package:hafiz_quran/models/schedule_item.dart';
import 'package:hafiz_quran/screens/memorization_form.dart';

class ScheduleView extends StatefulWidget {
  final ScheduleService scheduleService;

  const ScheduleView({
    super.key, 
    required this.scheduleService,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late List<Map<String, dynamic>> schedule;

  @override
  void initState() {
    super.initState();
    _updateSchedule();
  }

  void _updateSchedule() {
    setState(() {
      schedule = widget.scheduleService.getAllItems().map((item) => {
        'date': item.currentDate,
        'verses': item.verses,
        'status': item.status,
        'id': item.id,
        'item': item,
        'originalDate': item.originalDate,
      }).toList();
    });
  }

  String _formatVerses(List<Map<String, dynamic>> verses) {
    if (verses.isEmpty) return '';
    final firstVerse = verses.first;
    final lastVerse = verses.last;
    return '${firstVerse['surahName']} ${firstVerse['ayah']} - ${lastVerse['surahName']} ${lastVerse['ayah']}';
  }

  void _showScheduleOptions(BuildContext context, String itemId) {
    final item = widget.scheduleService.getAllItems().firstWhere((i) => i.id == itemId);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Reschedule'),
              onTap: () {
                Navigator.pop(context);
                _showRescheduleDialog(context, itemId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Reschedule From Date'),
              onTap: () {
                Navigator.pop(context);
                _showRescheduleFromDateDialog(context, itemId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Completed'),
              onTap: () {
                widget.scheduleService.markAsCompleted(itemId);
                _updateSchedule();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('Mark as Skipped'),
              onTap: () {
                widget.scheduleService.markAsSkipped(itemId);
                _updateSchedule();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, String itemId) {
    final item = widget.scheduleService.getAllItems().firstWhere((i) => i.id == itemId);
    DateTime selectedDate = item.currentDate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule'),
        content: SizedBox(
          height: 400,
          width: 300,
          child: CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              selectedDate = date;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.scheduleService.rescheduleItem(
                itemId,
                selectedDate,
                reason: 'User rescheduled',
              );
              _updateSchedule();
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleFromDateDialog(BuildContext context, String itemId) {
    final item = widget.scheduleService.getAllItems().firstWhere((i) => i.id == itemId);
    DateTime selectedDate = item.currentDate;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule From Date'),
        content: SizedBox(
          height: 400,
          width: 300,
          child: CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              selectedDate = date;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Mark all items before selected date as completed
              final items = widget.scheduleService.getAllItems();
              for (var scheduleItem in items) {
                if (scheduleItem.currentDate.isBefore(selectedDate)) {
                  widget.scheduleService.markAsCompleted(scheduleItem.id);
                }
              }
              
              // Reschedule the current item and all subsequent items
              final currentIndex = items.indexWhere((i) => i.id == itemId);
              if (currentIndex != -1) {
                for (int i = currentIndex; i < items.length; i++) {
                  if (items[i].status != ScheduleStatus.completed) {
                    widget.scheduleService.rescheduleItem(
                      items[i].id,
                      selectedDate.add(Duration(days: i - currentIndex)),
                      reason: 'Rescheduled from date',
                    );
                  }
                }
              }
              
              _updateSchedule();
              Navigator.pop(context);
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  void _showDayOptions(BuildContext context, String itemId) {
    final item = widget.scheduleService.getAllItems().firstWhere((i) => i.id == itemId);
    bool isMemorized = item.status == ScheduleStatus.completed;
    bool isSkipped = item.status == ScheduleStatus.skipped;
    bool isAbsent = item.status == ScheduleStatus.absent;
    int rating = item.rating;
    final noteController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            intl.DateFormat.yMMMMd().format(item.currentDate),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // States section
                               // Memorization Status
                CheckboxListTile(
                  title: const Text('تم الحفظ'),
                  value: isMemorized,
                  onChanged: (value) {
                    setState(() {
                      isMemorized = value ?? false;
                      if (isMemorized) {
                        isSkipped = false;
                      }
                    });
                  },
                ),
                
                // Skip Day
                CheckboxListTile(
                  title: const Text('تخطي اليوم'),
                  value: isSkipped,
                  onChanged: (value) {
                  widget.scheduleService.rescheduleItem(
                    itemId,
                    item.currentDate.add(const Duration(days: 1)),
                    reason: 'Skipped day',
                  );
                    setState(() {
                      isSkipped = value ?? false;
                      if (isSkipped) {
                        isMemorized = false;
                      }
                    });
                  },
                ),
                
                // Absent
                CheckboxListTile(
                  title: const Text('غياب'),
                  value: isAbsent,
                  onChanged: (value) {
                    setState(() => isAbsent = value ?? false);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Rating Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                

                // Notes
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the item with new values
                item.notes = noteController.text;
                
                // Update status based on checkboxes
                if (isMemorized) {
                  item.markAsCompleted();
                } else if (isSkipped) {
                  item.markAsSkipped(reason: 'تم التخطي');
                } else if (isAbsent) {
                  item.status = ScheduleStatus.absent;
                } else {
                  item.status = ScheduleStatus.pending;
                }
                
                item.setRating(rating);
                _updateSchedule();
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group schedule by day of week
    Map<String, List<Map<String, dynamic>>> scheduleByDay = {};
    for (var day in schedule) {
      final date = day['date'] as DateTime;
      final dayName = intl.DateFormat.EEEE().format(date);
      if (!scheduleByDay.containsKey(dayName)) {
        scheduleByDay[dayName] = [];
      }
      scheduleByDay[dayName]!.add(day);
    }

    // Get the unique days from the schedule
    final days = scheduleByDay.keys.toList()..sort((a, b) {
      final weekDays = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      return weekDays.indexOf(a).compareTo(weekDays.indexOf(b));
    });

    // Find the first actual scheduled date
    final firstScheduledDate = schedule.first['date'] as DateTime;
    final firstScheduledDay = intl.DateFormat.EEEE().format(firstScheduledDate);
    
    // Calculate how many empty cells we need at the start
    int emptyCellsAtStart = 0;
    for (int i = 0; i < days.length; i++) {
      if (days[i] == firstScheduledDay) {
        emptyCellsAtStart = i;
        break;
      }
    }

    // Calculate total number of rows needed, ensuring we have enough rows for all items
    int totalRows = (schedule.length + emptyCellsAtStart) ~/ days.length;
    if ((schedule.length + emptyCellsAtStart) % days.length != 0) {
      totalRows++;
    }

    return Directionality( 
      textDirection: TextDirection.rtl, 
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Memorization Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _updateSchedule();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ البدء: ${intl.DateFormat.yMMMMd().format(schedule.first['date'])}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DataTable2(
                  dataRowHeight: 180,
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 600,
                  dividerThickness: 1,
                  headingRowColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  columns: days.map((day) => DataColumn2(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    size: ColumnSize.L,
                  )).toList(),
                  rows: List.generate(
                    totalRows,
                    (rowIndex) => DataRow2(
                      color: MaterialStateProperty.all(
                        rowIndex % 2 == 0 
                          ? Colors.white 
                          : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      ),
                      cells: days.map((day) {
                        // Calculate the index in the schedule for this cell
                        final scheduleIndex = rowIndex * days.length + days.indexOf(day) - emptyCellsAtStart;
                        
                        // If this is before the first scheduled day, return empty cell
                        if (scheduleIndex < 0) {
                          return const DataCell(SizedBox());
                        }
                        
                        // If this is beyond the schedule length, return empty cell
                        if (scheduleIndex >= schedule.length) {
                          return const DataCell(SizedBox());
                        }
                        
                        final entry = schedule[scheduleIndex];
                        final date = entry['date'] as DateTime;
                        final verses = entry['verses'] as List<Map<String, dynamic>>;
                        final item = entry['item'] as ScheduleItem;
                        
                        return DataCell(
                          InkWell(
                            onTap: () => _showDayOptions(context, entry['id']),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      intl.DateFormat.yMMMMd().format(date),
                                      maxLines: 1,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatVerses(verses),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.getStatusColor().withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                      item.getStatusText(),
                                      style: TextStyle(
                                        color: item.getStatusColor(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                     if (item.rating > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < item.rating ? Icons.star : Icons.star_border,
                                          color: index < item.rating ? Colors.amber : Colors.grey,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                      ],
                                ],
                                ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ), 
      );
  }
}