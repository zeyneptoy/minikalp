import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import 'profile_provider.dart';

/// Aggregated data for a single month of the baby's life.
class MonthSummary {
  const MonthSummary({
    required this.photos,
    required this.feeding,
    required this.formulaMl,
    required this.stool,
    required this.wet,
    required this.sleepSeconds,
    required this.recordCount,
  });

  final List<({int id, String path})> photos;
  final int feeding;
  final int formulaMl;
  final int stool;
  final int wet;
  final int sleepSeconds;
  final int recordCount;

  static const empty = MonthSummary(
    photos: [],
    feeding: 0,
    formulaMl: 0,
    stool: 0,
    wet: 0,
    sleepSeconds: 0,
    recordCount: 0,
  );
}

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Fetches photos + aggregated records for [month] of the active baby.
final monthSummaryProvider =
    FutureProvider.autoDispose.family<MonthSummary, int>((ref, month) async {
  final babyId = ref.watch(currentBabyIdProvider);
  final profile = ref.watch(babyProfileProvider);
  if (babyId == null || profile == null) return MonthSummary.empty;

  final birth = profile.birthDate;
  final from = DateTime(birth.year, birth.month + month, birth.day);
  final to = DateTime(birth.year, birth.month + month + 1, birth.day);

  final api = ref.read(apiClientProvider);

  final photoRows = await api.listPhotos(babyId, month: month);
  final records = await api.listRecords(
    babyId,
    from: _d(from),
    to: _d(to),
  );

  var feeding = 0, formulaMl = 0, stool = 0, wet = 0, sleepSeconds = 0;
  for (final row in records) {
    final r = row as Map<String, dynamic>;
    switch (r['type']) {
      case 'breastfeeding':
        feeding++;
        break;
      case 'formula':
        formulaMl += (r['amount_ml'] as num?)?.toInt() ?? 0;
        break;
      case 'stool':
        stool++;
        break;
      case 'diaper':
        if (r['diaper_kind'] == 'wet' || r['diaper_kind'] == 'both') wet++;
        break;
      case 'sleep':
        sleepSeconds += (r['duration_seconds'] as num?)?.toInt() ?? 0;
        break;
    }
  }

  return MonthSummary(
    photos: photoRows.map((p) {
      final m = p as Map<String, dynamic>;
      return (id: (m['id'] as num).toInt(), path: m['path'] as String);
    }).toList(),
    feeding: feeding,
    formulaMl: formulaMl,
    stool: stool,
    wet: wet,
    sleepSeconds: sleepSeconds,
    recordCount: records.length,
  );
});
