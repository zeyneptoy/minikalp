import '../models/baby_record.dart';

/// The analytics period selector.
enum AnalyticsPeriod { daily, weekly, monthly }

extension AnalyticsPeriodLabel on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.daily:
        return 'Günlük';
      case AnalyticsPeriod.weekly:
        return 'Haftalık';
      case AnalyticsPeriod.monthly:
        return 'Aylık';
    }
  }
}

/// A labelled numeric data point for bar/line charts.
class ChartPoint {
  const ChartPoint(this.label, this.value);
  final String label;
  final double value;
}

/// A slice of the stool-color donut chart.
class StoolSlice {
  const StoolSlice(this.color, this.count);
  final StoolColor color;
  final int count;
}

/// A smart insight card entry.
class AnalyticsInsight {
  const AnalyticsInsight({required this.title, required this.message});
  final String title;
  final String message;
}

/// Everything the analytics tab renders for a given period.
class AnalyticsData {
  const AnalyticsData({
    required this.feeding,
    required this.sleep,
    required this.vomiting,
    required this.stool,
    required this.insights,
  });

  final List<ChartPoint> feeding;
  final List<ChartPoint> sleep; // hours
  final List<ChartPoint> vomiting;
  final List<StoolSlice> stool;
  final List<AnalyticsInsight> insights;
}

/// Deterministic mock analytics per period. No backend.
class AnalyticsMock {
  AnalyticsMock._();

  static AnalyticsData forPeriod(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return const AnalyticsData(
          feeding: [
            ChartPoint('00', 1),
            ChartPoint('04', 2),
            ChartPoint('08', 2),
            ChartPoint('12', 1),
            ChartPoint('16', 2),
            ChartPoint('20', 2),
          ],
          sleep: [
            ChartPoint('00', 3),
            ChartPoint('04', 2.5),
            ChartPoint('08', 1),
            ChartPoint('12', 1.5),
            ChartPoint('16', 1),
            ChartPoint('20', 2),
          ],
          vomiting: [
            ChartPoint('00', 0),
            ChartPoint('04', 0),
            ChartPoint('08', 1),
            ChartPoint('12', 0),
            ChartPoint('16', 1),
            ChartPoint('20', 0),
          ],
          stool: [
            StoolSlice(StoolColor.yellow, 2),
            StoolSlice(StoolColor.green, 1),
            StoolSlice(StoolColor.brown, 1),
          ],
          insights: _insights,
        );
      case AnalyticsPeriod.weekly:
        return const AnalyticsData(
          feeding: [
            ChartPoint('Pzt', 8),
            ChartPoint('Sal', 7),
            ChartPoint('Çar', 9),
            ChartPoint('Per', 8),
            ChartPoint('Cum', 10),
            ChartPoint('Cmt', 7),
            ChartPoint('Paz', 9),
          ],
          sleep: [
            ChartPoint('Pzt', 14),
            ChartPoint('Sal', 13.5),
            ChartPoint('Çar', 15),
            ChartPoint('Per', 14.2),
            ChartPoint('Cum', 13),
            ChartPoint('Cmt', 15.5),
            ChartPoint('Paz', 14.8),
          ],
          vomiting: [
            ChartPoint('Pzt', 1),
            ChartPoint('Sal', 0),
            ChartPoint('Çar', 2),
            ChartPoint('Per', 0),
            ChartPoint('Cum', 1),
            ChartPoint('Cmt', 0),
            ChartPoint('Paz', 0),
          ],
          stool: [
            StoolSlice(StoolColor.yellow, 9),
            StoolSlice(StoolColor.green, 4),
            StoolSlice(StoolColor.brown, 3),
            StoolSlice(StoolColor.black, 1),
          ],
          insights: _insights,
        );
      case AnalyticsPeriod.monthly:
        return const AnalyticsData(
          feeding: [
            ChartPoint('1.H', 56),
            ChartPoint('2.H', 60),
            ChartPoint('3.H', 58),
            ChartPoint('4.H', 62),
          ],
          sleep: [
            ChartPoint('1.H', 14.5),
            ChartPoint('2.H', 14.1),
            ChartPoint('3.H', 13.8),
            ChartPoint('4.H', 13.5),
          ],
          vomiting: [
            ChartPoint('1.H', 3),
            ChartPoint('2.H', 2),
            ChartPoint('3.H', 4),
            ChartPoint('4.H', 1),
          ],
          stool: [
            StoolSlice(StoolColor.yellow, 34),
            StoolSlice(StoolColor.green, 12),
            StoolSlice(StoolColor.brown, 10),
            StoolSlice(StoolColor.green, 0),
          ],
          insights: _insights,
        );
    }
  }

  static const List<AnalyticsInsight> _insights = [
    AnalyticsInsight(
      title: 'Beslenme & uyku',
      message: 'Gece uykusu azaldıkça gündüz emzirme sayısı arttı.',
    ),
    AnalyticsInsight(
      title: 'Ek gıda etkisi',
      message: 'Yeni gıdadan sonra kaka renginde değişiklik gözlendi.',
    ),
    AnalyticsInsight(
      title: 'Genel eğilim',
      message: 'Bu hafta kusma sayısı geçen haftaya göre azaldı.',
    ),
  ];
}
