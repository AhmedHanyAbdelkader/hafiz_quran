import 'package:flutter/material.dart';
import 'package:hafiz_quran/helpers/generate_schedule.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:hafiz_quran/models/memorization_plan.dart';
import 'package:hafiz_quran/screens/schedule_view.dart';
import 'package:hafiz_quran/services/schedule_service.dart';

class MemorizationForm extends StatefulWidget {
  final ScheduleService scheduleService;

  const MemorizationForm({
    super.key,
    required this.scheduleService,
  });

  @override
  State<MemorizationForm> createState() => _MemorizationFormState();
}

class _MemorizationFormState extends State<MemorizationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String studentName = '';
  MemorizationDirection direction = MemorizationDirection.forward;
  int startSurah = 1;
  int startAyah = 1;
  int endSurah = 114;
  int endAyah = 6;
  double dailyPages = 1.0;
  double revisionPages = 0.0;
  List<String> recitationDays = [];
  DateTime? startDate;
  DateTime? rescheduleFromDate;

  final List<String> daysOfWeek = [
    'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
  ];

  Future<List<Map<String, dynamic>>>? _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = loadSurahs();
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<List<Map<String, dynamic>>> loadSurahs() async {
    final List<Map<String, dynamic>> surahs = [];

    for (int i = 1; i <= 114; i++) {
      final String content = await rootBundle.loadString('assets/quran_data/surah/surah_$i.json');
      final Map<String, dynamic> surahData = jsonDecode(content);
      surahs.add({
        'number': surahData['number'],
        'name': surahData['name']['ar'],
        'ayahs': surahData['verses_count'],
      });
    }

    return surahs;
  }

  String? _validateStudentName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter student name';
    }
    return null;
  }

  String? _validateRecitationDays() {
    if (recitationDays.isEmpty) {
      return 'Please select at least one recitation day';
    }
    return null;
  }

  String? _validateStartDate() {
    if (startDate == null) {
      return 'Please select a start date';
    }
    return null;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && 
        _validateRecitationDays() == null && 
        _validateStartDate() == null) {
      setState(() => _isLoading = true);

      try {
        final chuncks = await generateScheduleChuks(
          startSurah: startSurah,
          startAyah: startAyah,
          endSurah: endSurah,
          endAyah: endAyah,
          direction: direction,
          dailyPages: dailyPages,
          recitationDays: recitationDays,
          startDate: startDate!,
        );
        final scheduleWithDates = generateScheduleWithDates(
          chuncks, 
          recitationDays, 
          startDate!,
          direction: direction,
        );
        // Initialize the schedule service with the generated schedule
        widget.scheduleService.initializeSchedule(scheduleWithDates,recitationDays);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleView(
                scheduleService: widget.scheduleService,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating schedule: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quran Memorization Plan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Student Name'),
                      validator: _validateStudentName,
                      onChanged: (value) => studentName = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<MemorizationDirection>(
                      decoration: const InputDecoration(labelText: 'Direction'),
                      value: direction,
                      items: const [
                        DropdownMenuItem(
                          value: MemorizationDirection.forward,
                          child: Text('من الفاتحة إلى الناس'),
                        ),
                        DropdownMenuItem(
                          value: MemorizationDirection.reverse,
                          child: Text('من الناس إلى الفاتحة'),
                        ),
                      ],
                      onChanged: (value) => setState(() => direction = value!),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: _surahsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final selectedStartSurah = snapshot.data!.firstWhere(
                            (surah) => surah['number'] == startSurah,
                            orElse: () => snapshot.data!.first,
                          );
                          final selectedEndSurah = snapshot.data!.firstWhere(
                            (surah) => surah['number'] == endSurah,
                            orElse: () => snapshot.data!.first,
                          );
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'Start Surah'),
                                      value: startSurah,
                                      items: snapshot.data!.map((surah) {
                                        return DropdownMenuItem<int>(
                                          value: surah['number'],
                                          child: Text('${surah['number']}. ${surah['name']}'),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() {
                                        startSurah = value!;
                                        startAyah = 1; // Reset ayah when surah changes
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'Start Ayah'),
                                      value: startAyah,
                                      items: List.generate(selectedStartSurah['ayahs'], (index) {
                                        return DropdownMenuItem<int>(
                                          value: index + 1,
                                          child: Text('Ayah ${index + 1}'),
                                        );
                                      }),
                                      onChanged: (value) => setState(() => startAyah = value!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'End Surah'),
                                      value: endSurah,
                                      items: snapshot.data!.map((surah) {
                                        return DropdownMenuItem<int>(
                                          value: surah['number'],
                                          child: Text('${surah['number']}. ${surah['name']}'),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() {
                                        endSurah = value!;
                                        endAyah = 1; // Reset ayah when surah changes
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(labelText: 'End Ayah'),
                                      value: endAyah,
                                      items: List.generate(selectedEndSurah['ayahs'], (index) {
                                        return DropdownMenuItem<int>(
                                          value: index + 1,
                                          child: Text('Ayah ${index + 1}'),
                                        );
                                      }),
                                      onChanged: (value) => setState(() => endAyah = value!),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                    Slider(
                      label: 'Daily Pages: ${dailyPages.toStringAsFixed(1)}',
                      value: dailyPages,
                      min: 0.5,
                      max: 5,
                      divisions: 9,
                      onChanged: (value) => setState(() => dailyPages = value),
                    ),
                    Slider(
                      label: 'Revision Pages: ${revisionPages.toStringAsFixed(1)}',
                      value: revisionPages,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (value) => setState(() => revisionPages = value),
                    ),
                    const SizedBox(height: 16),
                    Text('Recitation Days', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: daysOfWeek.map((day) {
                        final selected = recitationDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: selected,
                          onSelected: (isSelected) {
                            setState(() {
                              isSelected
                                  ? recitationDays.add(day)
                                  : recitationDays.remove(day);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_validateRecitationDays() != null)
                      Text(
                        _validateRecitationDays()!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(startDate == null
                            ? 'Start Date: not selected'
                            : 'Start Date: ${DateFormat.yMd().format(startDate!)}'),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectDate,
                          child: const Text('Select Date'),
                        )
                      ],
                    ),
                    if (_validateStartDate() != null)
                      Text(
                        _validateStartDate()!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Generate Schedule'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
