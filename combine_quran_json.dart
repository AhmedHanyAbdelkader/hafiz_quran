import 'dart:convert';
import 'dart:io';

void main() async {
  final Directory dir = Directory('assets/quran_data/surah');
  final List<FileSystemEntity> files = dir.listSync();
  final List<Map<String, dynamic>> allAyat = [];

  for (final file in files) {
    if (file is File && file.path.endsWith('.json')) {
      final String content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final String surahName = data["name"] ?? "unknown";
      final Map<String, dynamic> verses = data["verse"] ?? {};

      // Try to get page info from the Juz section or leave it 0
      int page = 0;
      if (data.containsKey("juz")) {
        final juzList = data["juz"];
        if (juzList is List && juzList.isNotEmpty) {
          page = int.tryParse(juzList[0]["index"]) ?? 0;
        }
      }

      verses.forEach((key, value) {
        final int? verseNumber = int.tryParse(key.replaceAll("verse_", ""));
        if (verseNumber != null) {
          allAyat.add({
            "surah": surahName,
            "ayah": verseNumber,
            "page": page
          });
        }
      });
    }
  }

  final File outFile = File('assets/quran_data/quran_data.json');
  await outFile.writeAsString(jsonEncode(allAyat), flush: true);

  print('✅ quran_data.json created with ${allAyat.length} ayat.');
}
