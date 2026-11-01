import 'package:flutter_test/flutter_test.dart';
import 'package:minikalp/core/api/record_mapper.dart';
import 'package:minikalp/core/models/baby_record.dart';

void main() {
  group('RecordMapper enum edge cases', () {
    test('breastfeeding round-trips (side + duration)', () {
      final body = RecordMapper.toBody(
        BreastfeedingRecord(side: BreastSide.both, duration: const Duration(minutes: 18)),
      );
      expect(body['type'], 'breastfeeding');
      expect(body['side'], 'both');
      expect(body['duration_seconds'], 1080);

      final back = RecordMapper.fromJson({
        'id': 7,
        'type': 'breastfeeding',
        'side': 'both',
        'duration_seconds': 1080,
        'recorded_at': '2026-01-01T10:00:00.000Z',
      }) as BreastfeedingRecord;
      expect(back.id, '7');
      expect(back.side, BreastSide.both);
      expect(back.duration.inMinutes, 18);
    });

    test('formula milk_type snake_case', () {
      final body = RecordMapper.toBody(
        FormulaRecord(milkType: MilkType.breastMilk, ml: 90),
      );
      expect(body['milk_type'], 'breast_milk');
      final back = RecordMapper.fromJson({
        'type': 'formula',
        'milk_type': 'breast_milk',
        'amount_ml': 90,
        'recorded_at': '2026-01-01T10:00:00.000Z',
      }) as FormulaRecord;
      expect(back.milkType, MilkType.breastMilk);
      expect(back.ml, 90);
    });

    test('stool white_gray + solid stool_change', () {
      final stool = RecordMapper.toBody(
        StoolRecord(color: StoolColor.whiteGray, consistency: StoolConsistency.lumpy),
      );
      expect(stool['stool_color'], 'white_gray');
      expect(stool['stool_consistency'], 'lumpy');

      final solid = RecordMapper.toBody(
        SolidFoodRecord(foodName: 'Elma', reaction: SolidReaction.stoolChange),
      );
      expect(solid['reaction'], 'stool_change');

      final backStool = RecordMapper.fromJson({
        'type': 'stool',
        'stool_color': 'white_gray',
        'stool_consistency': 'lumpy',
        'recorded_at': '2026-01-01T10:00:00.000Z',
      }) as StoolRecord;
      expect(backStool.color, StoolColor.whiteGray);
    });

    test('vomit kind + symptoms', () {
      final body = RecordMapper.toBody(
        VomitRecord(
          kind: VomitKind.spitUp,
          amount: VomitAmount.medium,
          symptoms: {VomitSymptom.fever, VomitSymptom.fatigue},
        ),
      );
      expect(body['vomit_kind'], 'spit_up');
      expect(body['vomit_amount'], 'medium');
      expect((body['symptoms'] as List).toSet(), {'fever', 'fatigue'});

      final back = RecordMapper.fromJson({
        'type': 'vomit',
        'vomit_kind': 'spit_up',
        'vomit_amount': 'medium',
        'symptoms': ['fever', 'fatigue'],
        'recorded_at': '2026-01-01T10:00:00.000Z',
      }) as VomitRecord;
      expect(back.kind, VomitKind.spitUp);
      expect(back.symptoms, {VomitSymptom.fever, VomitSymptom.fatigue});
    });

    test('fever + sleep', () {
      final fever = RecordMapper.toBody(
        FeverRecord(temperature: 38.4, method: FeverMethod.ear),
      );
      expect(fever['temperature'], 38.4);
      expect(fever['fever_method'], 'ear');

      final sleep = RecordMapper.toBody(
        SleepRecord(
          duration: const Duration(hours: 1, minutes: 20),
          dayNight: DayNight.night,
          quality: 5,
        ),
      );
      expect(sleep['duration_seconds'], 4800);
      expect(sleep['day_night'], 'night');
      expect(sleep['quality'], 5);
    });
  });
}
