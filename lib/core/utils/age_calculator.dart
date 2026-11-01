/// The result of computing a baby's age from a birth date.
///
/// All fields are plain integers so the type is trivially testable.
class BabyAge {
  const BabyAge({
    required this.months,
    required this.days,
    required this.totalDays,
    required this.weeks,
  });

  /// Completed calendar months since birth.
  final int months;

  /// Remaining days after the completed months (the "x days" part).
  final int days;

  /// Total number of days lived.
  final int totalDays;

  /// Total completed weeks lived.
  final int weeks;

  @override
  String toString() =>
      'BabyAge(months: $months, days: $days, totalDays: $totalDays, '
      'weeks: $weeks)';

  @override
  bool operator ==(Object other) =>
      other is BabyAge &&
      other.months == months &&
      other.days == days &&
      other.totalDays == totalDays &&
      other.weeks == weeks;

  @override
  int get hashCode => Object.hash(months, days, totalDays, weeks);
}

/// Pure age calculation helpers. No Flutter dependencies, fully testable.
class AgeCalculator {
  AgeCalculator._();

  /// Computes a [BabyAge] from [birthDate] relative to [now]
  /// (defaults to `DateTime.now()`).
  ///
  /// Dates are normalized to midnight so the result is not affected by the
  /// time of day. A future birth date yields an all-zero age.
  static BabyAge calculate(DateTime birthDate, {DateTime? now}) {
    final reference = _dateOnly(now ?? DateTime.now());
    final birth = _dateOnly(birthDate);

    if (!birth.isBefore(reference)) {
      // Birth date is today or in the future.
      if (birth.isAtSameMomentAs(reference)) {
        return const BabyAge(months: 0, days: 0, totalDays: 0, weeks: 0);
      }
      return const BabyAge(months: 0, days: 0, totalDays: 0, weeks: 0);
    }

    final totalDays = reference.difference(birth).inDays;
    final weeks = totalDays ~/ 7;

    // Walk forward whole months without overflowing to keep the day remainder
    // accurate across months of different lengths.
    var months = 0;
    var cursor = birth;
    while (true) {
      final next = _addMonths(cursor, 1);
      if (next.isAfter(reference)) break;
      cursor = next;
      months++;
    }
    final days = reference.difference(cursor).inDays;

    return BabyAge(
      months: months,
      days: days,
      totalDays: totalDays,
      weeks: weeks,
    );
  }

  /// Turkish display string for an age.
  ///
  /// Examples:
  /// - under 1 month: "18 günlük"
  /// - with months and days: "2 ay 14 günlük"
  /// - exact months: "12 aylık"
  static String formatTurkish(BabyAge age) {
    if (age.months == 0) {
      return '${age.days} günlük';
    }
    if (age.days == 0) {
      return '${age.months} aylık';
    }
    return '${age.months} ay ${age.days} günlük';
  }

  /// Convenience: compute and format in one call.
  static String describe(DateTime birthDate, {DateTime? now}) =>
      formatTurkish(calculate(birthDate, now: now));

  // ----- helpers -----

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Adds [count] months to [date], clamping the day to the target month's
  /// length (e.g. Jan 31 + 1 month -> Feb 28/29).
  static DateTime _addMonths(DateTime date, int count) {
    final totalMonth = date.month - 1 + count;
    final year = date.year + totalMonth ~/ 12;
    final month = totalMonth % 12 + 1;
    final lastDay = _daysInMonth(year, month);
    final day = date.day < lastDay ? date.day : lastDay;
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) {
    // Day 0 of next month == last day of this month.
    final beginningNextMonth =
        (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1)).day;
  }
}
