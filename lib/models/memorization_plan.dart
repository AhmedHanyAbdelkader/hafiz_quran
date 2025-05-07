enum MemorizationDirection { forward, reverse }

class MemorizationPlan {
  final String studentName;
  final MemorizationDirection direction;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final double dailyPages;
  final double revisionPages;
  final List<String> recitationDays; // ["Saturday", "Monday", ...]
  final DateTime startDate;

  MemorizationPlan({
    required this.studentName,
    required this.direction,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.dailyPages,
    required this.revisionPages,
    required this.recitationDays,
    required this.startDate,
  });
}
