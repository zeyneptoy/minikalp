/// A single mother's-diary entry, tied to the baby's age month when written.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.month,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int month;
  final String body;
  final DateTime createdAt;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: (json['id'] as num).toInt(),
        month: (json['month'] as num?)?.toInt() ?? 0,
        body: json['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
      );
}
