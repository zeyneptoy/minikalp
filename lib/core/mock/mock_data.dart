import '../models/baby_profile.dart';

/// Static mock data for the UI prototype. There is no backend; these values
/// stand in for whatever a real data layer would provide later.
class MockData {
  MockData._();

  /// A demo baby profile. Birth date is relative to "now" so the age label
  /// stays realistic whenever the app is run.
  static BabyProfile get demoBaby => BabyProfile(
        name: 'Defne',
        birthDate: DateTime.now().subtract(const Duration(days: 74)),
        gender: Gender.unspecified,
      );

  /// Mock timeline of today's activities (newest first).
  static const List<MockActivity> todayTimeline = [
    MockActivity(
      icon: ActivityIcon.feeding,
      title: 'Emzirme',
      subtitle: 'Sol göğüs · 18 dk',
      time: '14:30',
    ),
    MockActivity(
      icon: ActivityIcon.diaper,
      title: 'Bez değişimi',
      subtitle: 'Sarı, normal',
      time: '13:10',
    ),
    MockActivity(
      icon: ActivityIcon.sleep,
      title: 'Uyku',
      subtitle: '1 saat 20 dk',
      time: '11:40',
    ),
    MockActivity(
      icon: ActivityIcon.vomit,
      title: 'Kusma',
      subtitle: 'Az miktarda, besleme sonrası',
      time: '10:05',
    ),
  ];

  /// Mock weekly feeding counts (Mon-Sun) for charts.
  static const List<double> weeklyFeedings = [7, 8, 6, 9, 8, 10, 7];

  /// Mock weekly sleep hours (Mon-Sun) for charts.
  static const List<double> weeklySleepHours = [14, 13.5, 15, 14.2, 13, 15.5, 14.8];
}

/// Logical activity categories, mapped to icons at the widget layer.
enum ActivityIcon { feeding, diaper, sleep, vomit, health, growth }

/// A single mock activity entry used by the timeline.
class MockActivity {
  const MockActivity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final ActivityIcon icon;
  final String title;
  final String subtitle;
  final String time;
}
