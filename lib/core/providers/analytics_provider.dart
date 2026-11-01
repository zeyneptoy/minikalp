import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/analytics_mock.dart';
import '../models/baby_record.dart';
import 'records_provider.dart';

/// Live analytics computed from the baby's actual records for the selected
/// period. Produces the same [AnalyticsData] shape the charts already consume.
final analyticsProvider =
    Provider.family<AnalyticsData, AnalyticsPeriod>((ref, period) {
  final records = ref.watch(recordsProvider);
  final now = DateTime.now();

  switch (period) {
    case AnalyticsPeriod.daily:
      return _daily(records, now);
    case AnalyticsPeriod.weekly:
      return _weekly(records, now);
    case AnalyticsPeriod.monthly:
      return _monthly(records, now);
  }
});

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isFeeding(BabyRecord r) => r is BreastfeedingRecord || r is FormulaRecord;

double _sleepHours(Iterable<BabyRecord> rs) {
  var seconds = 0;
  for (final r in rs) {
    if (r is SleepRecord) seconds += r.duration.inSeconds;
  }
  return seconds / 3600.0;
}

List<StoolSlice> _stoolSlices(Iterable<BabyRecord> rs) {
  final counts = <StoolColor, int>{};
  for (final r in rs) {
    if (r is StoolRecord) {
      counts[r.color] = (counts[r.color] ?? 0) + 1;
    }
  }
  final slices = counts.entries
      .map((e) => StoolSlice(e.key, e.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return slices;
}

AnalyticsData _daily(List<BabyRecord> records, DateTime now) {
  final today = records.where((r) => _sameDay(r.timestamp, now)).toList();
  const slots = [0, 4, 8, 12, 16, 20];

  List<ChartPoint> perSlot(bool Function(BabyRecord) test) => [
        for (final s in slots)
          ChartPoint(
            s.toString().padLeft(2, '0'),
            today
                .where((r) =>
                    test(r) && r.timestamp.hour >= s && r.timestamp.hour < s + 4)
                .length
                .toDouble(),
          ),
      ];

  final sleep = [
    for (final s in slots)
      ChartPoint(
        s.toString().padLeft(2, '0'),
        _sleepHours(today.where(
            (r) => r.timestamp.hour >= s && r.timestamp.hour < s + 4)),
      ),
  ];

  return AnalyticsData(
    feeding: perSlot(_isFeeding),
    sleep: sleep,
    vomiting: perSlot((r) => r is VomitRecord),
    stool: _stoolSlices(today),
    insights: _insights(today, 'bugün'),
  );
}

AnalyticsData _weekly(List<BabyRecord> records, DateTime now) {
  const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final days = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];

  final feeding = <ChartPoint>[];
  final sleep = <ChartPoint>[];
  final vomiting = <ChartPoint>[];
  final weekRecords = <BabyRecord>[];

  for (final day in days) {
    final dayRecords =
        records.where((r) => _sameDay(r.timestamp, day)).toList();
    weekRecords.addAll(dayRecords);
    final label = labels[day.weekday - 1];
    feeding.add(ChartPoint(label, dayRecords.where(_isFeeding).length.toDouble()));
    sleep.add(ChartPoint(label, _sleepHours(dayRecords)));
    vomiting.add(ChartPoint(
        label, dayRecords.whereType<VomitRecord>().length.toDouble()));
  }

  return AnalyticsData(
    feeding: feeding,
    sleep: sleep,
    vomiting: vomiting,
    stool: _stoolSlices(weekRecords),
    insights: _insights(weekRecords, 'bu hafta'),
  );
}

AnalyticsData _monthly(List<BabyRecord> records, DateTime now) {
  // Four weeks ending today (1.H = oldest).
  final feeding = <ChartPoint>[];
  final sleep = <ChartPoint>[];
  final vomiting = <ChartPoint>[];
  final monthRecords = <BabyRecord>[];

  for (var w = 0; w < 4; w++) {
    final end = now.subtract(Duration(days: 7 * (3 - w)));
    final start = end.subtract(const Duration(days: 6));
    final weekRecords = records
        .where((r) =>
            !r.timestamp.isBefore(DateTime(start.year, start.month, start.day)) &&
            !r.timestamp.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59)))
        .toList();
    monthRecords.addAll(weekRecords);
    final label = '${w + 1}.H';
    feeding.add(ChartPoint(label, weekRecords.where(_isFeeding).length.toDouble()));
    sleep.add(ChartPoint(label, _sleepHours(weekRecords) / 7.0)); // avg hours/day
    vomiting.add(ChartPoint(
        label, weekRecords.whereType<VomitRecord>().length.toDouble()));
  }

  return AnalyticsData(
    feeding: feeding,
    sleep: sleep,
    vomiting: vomiting,
    stool: _stoolSlices(monthRecords),
    insights: _insights(monthRecords, 'bu ay'),
  );
}

List<AnalyticsInsight> _insights(List<BabyRecord> rs, String span) {
  if (rs.isEmpty) {
    return const [
      AnalyticsInsight(
        title: 'Veri bekleniyor',
        message: 'Kayıt ekledikçe burada sana özel içgörüler göstereceğiz.',
      ),
    ];
  }

  final feeding = rs.where(_isFeeding).length;
  final sleepH = _sleepHours(rs);
  final vomit = rs.whereType<VomitRecord>().length;

  return [
    AnalyticsInsight(
      title: 'Beslenme',
      message: '$span toplam $feeding beslenme kaydı var.',
    ),
    AnalyticsInsight(
      title: 'Uyku',
      message: '$span toplam ${sleepH.toStringAsFixed(1)} saat uyku kaydedildi.',
    ),
    if (vomit > 0)
      AnalyticsInsight(
        title: 'Kusma',
        message: '$span $vomit kez kusma kaydedildi. Sürerse doktorunuza danışın.',
      ),
  ];
}
