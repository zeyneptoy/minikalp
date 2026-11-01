// Unit tests for the pure age calculator and its Turkish formatting.

import 'package:flutter_test/flutter_test.dart';
import 'package:minikalp/core/utils/age_calculator.dart';

void main() {
  group('AgeCalculator.calculate', () {
    test('under one month counts days only', () {
      final now = DateTime(2026, 1, 19);
      final birth = DateTime(2026, 1, 1);
      final age = AgeCalculator.calculate(birth, now: now);

      expect(age.months, 0);
      expect(age.days, 18);
      expect(age.totalDays, 18);
      expect(age.weeks, 2);
    });

    test('months and remaining days', () {
      final now = DateTime(2026, 3, 15);
      final birth = DateTime(2026, 1, 1);
      final age = AgeCalculator.calculate(birth, now: now);

      expect(age.months, 2);
      expect(age.days, 14);
    });

    test('exact month boundary has zero remaining days', () {
      final now = DateTime(2027, 1, 1);
      final birth = DateTime(2026, 1, 1);
      final age = AgeCalculator.calculate(birth, now: now);

      expect(age.months, 12);
      expect(age.days, 0);
    });

    test('clamps month-end correctly (Jan 31 -> Feb)', () {
      final now = DateTime(2026, 3, 1);
      final birth = DateTime(2026, 1, 31);
      final age = AgeCalculator.calculate(birth, now: now);

      // Jan 31 + 1 month clamps to Feb 28 (2026 is not a leap year),
      // so by Mar 1 the baby is 1 month and 1 day old.
      expect(age.months, 1);
      expect(age.days, 1);
    });

    test('future birth date yields zero age', () {
      final now = DateTime(2026, 1, 1);
      final birth = DateTime(2026, 6, 1);
      final age = AgeCalculator.calculate(birth, now: now);

      expect(age, const BabyAge(months: 0, days: 0, totalDays: 0, weeks: 0));
    });
  });

  group('AgeCalculator.formatTurkish', () {
    test('under one month', () {
      expect(
        AgeCalculator.formatTurkish(
          const BabyAge(months: 0, days: 18, totalDays: 18, weeks: 2),
        ),
        '18 günlük',
      );
    });

    test('months and days', () {
      expect(
        AgeCalculator.formatTurkish(
          const BabyAge(months: 2, days: 14, totalDays: 74, weeks: 10),
        ),
        '2 ay 14 günlük',
      );
    });

    test('exact months', () {
      expect(
        AgeCalculator.formatTurkish(
          const BabyAge(months: 12, days: 0, totalDays: 365, weeks: 52),
        ),
        '12 aylık',
      );
    });
  });
}
