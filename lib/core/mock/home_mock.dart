import '../models/record_type.dart';
import '../utils/age_calculator.dart';
import '../widgets/warning_banner.dart';

/// Info for the "Son beslenme" card.
class LastFeedingInfo {
  const LastFeedingInfo({required this.summary, required this.agoText});

  /// E.g. "Sol meme" or "Mama • 90 ml".
  final String summary;

  /// E.g. "1 sa 20 dk önce".
  final String agoText;
}

/// Aggregated numbers for the "Bugünün özeti" card.
class DailySummary {
  const DailySummary({
    required this.breastfeedingCount,
    required this.formulaMl,
    required this.stoolCount,
    required this.wetDiapers,
    required this.totalSleep,
  });

  final int breastfeedingCount;
  final int formulaMl;
  final int stoolCount;
  final int wetDiapers;

  /// Preformatted sleep total, e.g. "14s 20dk".
  final String totalSleep;
}

/// A single calm smart-alert entry.
class SmartAlert {
  const SmartAlert({required this.level, required this.message, this.title});

  final WarningLevel level;
  final String message;
  final String? title;
}

/// A single entry in the "Bugün ne var?" timeline.
class TimelineEntry {
  const TimelineEntry({
    required this.type,
    required this.detail,
    required this.time,
  });

  final RecordType type;

  /// Short description, e.g. "Sol meme · 18 dk".
  final String detail;

  /// Clock label, e.g. "14:30".
  final String time;
}

/// Age-specific tip shown at the bottom of the home screen.
class AgeTip {
  const AgeTip({required this.title, required this.message});

  final String title;
  final String message;
}

/// Everything the home screen needs, generated from the baby's age so the
/// mock values feel sensible for a 0–12 month old. There is no backend — this
/// is deterministic prototype data.
class HomeDashboardData {
  const HomeDashboardData({
    required this.lastFeeding,
    required this.nextFeedingEstimate,
    required this.summary,
    required this.alerts,
    required this.timeline,
    required this.tip,
  });

  final LastFeedingInfo lastFeeding;
  final String nextFeedingEstimate;
  final DailySummary summary;
  final List<SmartAlert> alerts;
  final List<TimelineEntry> timeline;
  final AgeTip tip;
}

/// Builds [HomeDashboardData] from a baby age.
class HomeMock {
  HomeMock._();

  static HomeDashboardData forAge(BabyAge age) {
    final months = age.months;

    // Younger babies feed more often and sleep more.
    final feedCount = _clamp(11 - months, 6, 12);
    final formula = months < 6 ? 180 : 300;
    final stool = months == 0 ? 4 : 2;
    const wet = 6;
    final sleep = months == 0
        ? '16s 10dk'
        : months < 4
        ? '15s 00dk'
        : '14s 20dk';

    return HomeDashboardData(
      lastFeeding: const LastFeedingInfo(
        summary: 'Sol meme',
        agoText: '1 sa 20 dk önce',
      ),
      nextFeedingEstimate: months < 4
          ? 'Tahmini sonraki beslenme ~40 dk sonra'
          : 'Tahmini sonraki beslenme ~1 sa 20 dk sonra',
      summary: DailySummary(
        breastfeedingCount: feedCount,
        formulaMl: formula,
        stoolCount: stool,
        wetDiapers: wet,
        totalSleep: sleep,
      ),
      alerts: _alerts(),
      timeline: _timeline(),
      tip: _tipForMonths(months),
    );
  }

  static List<SmartAlert> _alerts() => const [
    SmartAlert(
      level: WarningLevel.info,
      title: 'İyi gidiyor',
      message: 'Bugün 6 ıslak bez kaydedildi, bu iyi bir işaret.',
    ),
    SmartAlert(
      level: WarningLevel.caution,
      title: 'Hatırlatma',
      message:
          'Son tartımın üzerinden 2 hafta geçti, yeni ölçüm '
          'ekleyebilirsin.',
    ),
    SmartAlert(
      level: WarningLevel.important,
      title: 'Takip et',
      message:
          'Bugün 2 kez kusma kaydedildi, devam ederse doktorunuza '
          'danışın.',
    ),
  ];

  static List<TimelineEntry> _timeline() => const [
    TimelineEntry(
      type: RecordType.breastfeeding,
      detail: 'Sol meme · 18 dk',
      time: '14:30',
    ),
    TimelineEntry(type: RecordType.diaper, detail: 'Islak', time: '13:10'),
    TimelineEntry(type: RecordType.sleep, detail: '1 sa 20 dk', time: '11:40'),
    TimelineEntry(
      type: RecordType.vomit,
      detail: 'Az miktarda, besleme sonrası',
      time: '10:05',
    ),
    TimelineEntry(type: RecordType.formula, detail: '90 ml', time: '08:30'),
  ];

  /// Age-tailored guidance. Messages change across the 0–12 month range.
  static AgeTip _tipForMonths(int months) {
    if (months < 1) {
      return const AgeTip(
        title: 'Bu dönemde',
        message:
            'Yenidoğanlar günde 8-12 kez beslenir. Sık beslenme '
            'tamamen normaldir.',
      );
    }
    if (months < 4) {
      return const AgeTip(
        title: 'Bu dönemde',
        message:
            'Uyku düzeni oturmaya başlar; bebekler günde 14-17 saat '
            'uyuyabilir.',
      );
    }
    if (months < 6) {
      return const AgeTip(
        title: 'Bu dönemde',
        message:
            'Baş kontrolü güçleniyor. Karın üstü (tummy time) için '
            'güzel bir dönem.',
      );
    }
    if (months < 9) {
      return const AgeTip(
        title: 'Bu dönemde',
        message:
            'Ek gıdaya geçiş zamanı. Yeni besinleri tek tek ve '
            'birkaç gün arayla deneyin.',
      );
    }
    return const AgeTip(
      title: 'Bu dönemde',
      message:
          'Parmakla tutarak yemeyi (finger food) teşvik edebilir, '
          'çeşitliliği artırabilirsiniz.',
    );
  }

  static int _clamp(int v, int min, int max) =>
      v < min ? min : (v > max ? max : v);
}
