import 'package:hafiz_quran/models/memorization_plan.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

Future<List<List<Map<String, dynamic>>>> generateScheduleChuks({
  required int startSurah,
  required int startAyah,
  required int endSurah,
  required int endAyah,
  required MemorizationDirection direction,
  required double dailyPages,
  required List<String> recitationDays,
  required DateTime startDate,
}) async {
  // Flatten Quran into a list of {surah, ayah, page}
  List<Map<String, dynamic>> allAyahs = [];

  for (int i = 1; i <= 114; i++) {
    final content = await rootBundle.loadString('assets/quran_data/surah/surah_$i.json');
    final surahData = jsonDecode(content);
    final List verses = surahData['verses'];

    for (var verse in verses) {
      allAyahs.add({
        'surah': i,
        'surahName': surahData['name']['ar'],
        'ayah': verse['number'],
        'page': verse['page'],
      });
    }
  }

  if (direction == MemorizationDirection.reverse) {
    allAyahs = allAyahs.reversed.toList();
  }

  // Find the range of ayahs
  int startIndex = allAyahs.indexWhere((a) => a['surah'] == startSurah && a['ayah'] == startAyah);
  int endIndex = allAyahs.indexWhere((a) => a['surah'] == endSurah && a['ayah'] == endAyah);

  // Make sure start is before end
  if (startIndex > endIndex) {
    final temp = startIndex;
    startIndex = endIndex;
    endIndex = temp;
  }

  List<Map<String, dynamic>> range = allAyahs.sublist(startIndex, endIndex + 1);

  // Reverse the range if direction is reverse
  if (direction == MemorizationDirection.reverse) {
    range = range.reversed.toList();
  }

  // Group by pages
  List<List<Map<String, dynamic>>> chunks = [];
  List<Map<String, dynamic>> currentChunk = [];
  int currentPage = range[0]['page'];
  int targetPages = dailyPages.round();

  for (var ayah in range) {
    if (ayah['page'] - currentPage >= targetPages && currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
      currentChunk = [];
      currentPage = ayah['page'];
    }
    currentChunk.add({
      'surah': ayah['surah'],
      'ayah': ayah['ayah'],
      'surahName': ayah['surahName'],
    });
  }

  if (currentChunk.isNotEmpty) {
    chunks.add(currentChunk);
  }

print('**************************************');
  print(chunks);
print('**************************************');

  return chunks;
}

List<Map<String, dynamic>> generateScheduleWithDates(
  List<List<Map<String, dynamic>>> chunks,
  List<String> recitationDays,
  DateTime startDate,
  {MemorizationDirection direction = MemorizationDirection.forward}
) {
  List<Map<String, dynamic>> scheduledDays = [];
  DateTime currentDate = startDate;

  // Reverse the chunks if direction is reverse
  if (direction == MemorizationDirection.reverse) {
    chunks = chunks.reversed.toList();
  }

  int chunkIndex = 0;
  while (chunkIndex < chunks.length) {
    if (recitationDays.contains(DateFormat.EEEE().format(currentDate))) {
      scheduledDays.add({
        'date': currentDate,
        'verses': chunks[chunkIndex],
      });
      chunkIndex++;
    }
    currentDate = currentDate.add(const Duration(days: 1));
  }
  print('///////////////////////////////////////');
  print(scheduledDays);
  print('///////////////////////////////////////');

  return scheduledDays;
}
