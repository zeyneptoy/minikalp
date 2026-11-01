import '../models/baby_record.dart';

/// Converts between the app's [BabyRecord] hierarchy and the backend's flat
/// record JSON (the `/babies/{id}/records` payload).
class RecordMapper {
  RecordMapper._();

  // --- enum <-> wire string helpers ------------------------------------------

  static String _breastSide(BreastSide s) => s.name; // left | right | both
  static BreastSide _breastSideFrom(String? s) =>
      BreastSide.values.firstWhere((e) => e.name == s,
          orElse: () => BreastSide.left);

  static String _milkType(MilkType m) =>
      m == MilkType.breastMilk ? 'breast_milk' : 'formula';
  static MilkType _milkTypeFrom(String? s) =>
      s == 'breast_milk' ? MilkType.breastMilk : MilkType.formula;

  static String _reaction(SolidReaction r) =>
      r == SolidReaction.stoolChange ? 'stool_change' : r.name;
  static SolidReaction _reactionFrom(String? s) {
    switch (s) {
      case 'rash':
        return SolidReaction.rash;
      case 'vomit':
        return SolidReaction.vomit;
      case 'stool_change':
        return SolidReaction.stoolChange;
      default:
        return SolidReaction.none;
    }
  }

  static String _stoolColor(StoolColor c) =>
      c == StoolColor.whiteGray ? 'white_gray' : c.name;
  static StoolColor _stoolColorFrom(String? s) {
    if (s == 'white_gray') return StoolColor.whiteGray;
    return StoolColor.values
        .firstWhere((e) => e.name == s, orElse: () => StoolColor.yellow);
  }

  static StoolConsistency _consistencyFrom(String? s) =>
      StoolConsistency.values
          .firstWhere((e) => e.name == s, orElse: () => StoolConsistency.normal);

  static DiaperKind _diaperFrom(String? s) =>
      DiaperKind.values.firstWhere((e) => e.name == s,
          orElse: () => DiaperKind.wet);

  static String _vomitKind(VomitKind k) =>
      k == VomitKind.spitUp ? 'spit_up' : 'forceful';
  static VomitKind _vomitKindFrom(String? s) =>
      s == 'forceful' ? VomitKind.forceful : VomitKind.spitUp;

  static VomitAmount _vomitAmountFrom(String? s) =>
      VomitAmount.values.firstWhere((e) => e.name == s,
          orElse: () => VomitAmount.low);

  static VomitSymptom? _symptomFrom(String s) {
    for (final e in VomitSymptom.values) {
      if (e.name == s) return e;
    }
    return null;
  }

  static DayNight _dayNightFrom(String? s) =>
      s == 'night' ? DayNight.night : DayNight.day;

  static FeverMethod _feverMethodFrom(String? s) =>
      FeverMethod.values.firstWhere((e) => e.name == s,
          orElse: () => FeverMethod.armpit);

  // --- app record -> API body ------------------------------------------------

  static Map<String, dynamic> toBody(BabyRecord r) {
    final base = <String, dynamic>{
      'recorded_at': r.timestamp.toIso8601String(),
    };

    if (r is BreastfeedingRecord) {
      return {
        ...base,
        'type': 'breastfeeding',
        'side': _breastSide(r.side),
        'duration_seconds': r.duration.inSeconds,
      };
    }
    if (r is FormulaRecord) {
      return {
        ...base,
        'type': 'formula',
        'milk_type': _milkType(r.milkType),
        'amount_ml': r.ml,
      };
    }
    if (r is SolidFoodRecord) {
      return {
        ...base,
        'type': 'solid_food',
        'food_name': r.foodName,
        'reaction': _reaction(r.reaction),
      };
    }
    if (r is StoolRecord) {
      return {
        ...base,
        'type': 'stool',
        'stool_color': _stoolColor(r.color),
        'stool_consistency': r.consistency.name,
        if (r.note != null) 'note': r.note,
        if (r.photoPath != null) 'photo_path': r.photoPath,
      };
    }
    if (r is DiaperRecord) {
      return {...base, 'type': 'diaper', 'diaper_kind': r.kind.name};
    }
    if (r is VomitRecord) {
      return {
        ...base,
        'type': 'vomit',
        'vomit_kind': _vomitKind(r.kind),
        'vomit_amount': r.amount.name,
        'symptoms': r.symptoms.map((s) => s.name).toList(),
        if (r.colorNote != null) 'color_note': r.colorNote,
      };
    }
    if (r is SleepRecord) {
      return {
        ...base,
        'type': 'sleep',
        'duration_seconds': r.duration.inSeconds,
        'day_night': r.dayNight.name,
        'quality': r.quality,
      };
    }
    if (r is FeverRecord) {
      return {
        ...base,
        'type': 'fever',
        'temperature': r.temperature,
        'fever_method': r.method.name,
      };
    }
    if (r is MedicineRecord) {
      return {...base, 'type': 'medicine', 'medicine_name': r.name};
    }

    throw ArgumentError('Unknown record type: ${r.runtimeType}');
  }

  // --- API json -> app record ------------------------------------------------

  static BabyRecord? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final ts = DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
        DateTime.now();

    switch (json['type'] as String?) {
      case 'breastfeeding':
        return BreastfeedingRecord(
          id: id,
          timestamp: ts,
          side: _breastSideFrom(json['side'] as String?),
          duration: Duration(seconds: (json['duration_seconds'] as num?)?.toInt() ?? 0),
        );
      case 'formula':
        return FormulaRecord(
          id: id,
          timestamp: ts,
          milkType: _milkTypeFrom(json['milk_type'] as String?),
          ml: (json['amount_ml'] as num?)?.toInt() ?? 0,
        );
      case 'solid_food':
        return SolidFoodRecord(
          id: id,
          timestamp: ts,
          foodName: json['food_name'] as String? ?? '',
          reaction: _reactionFrom(json['reaction'] as String?),
        );
      case 'stool':
        return StoolRecord(
          id: id,
          timestamp: ts,
          color: _stoolColorFrom(json['stool_color'] as String?),
          consistency: _consistencyFrom(json['stool_consistency'] as String?),
          note: json['note'] as String?,
          photoPath: json['photo_path'] as String?,
        );
      case 'diaper':
        return DiaperRecord(
          id: id,
          timestamp: ts,
          kind: _diaperFrom(json['diaper_kind'] as String?),
        );
      case 'vomit':
        final symptoms = <VomitSymptom>{};
        for (final s in (json['symptoms'] as List<dynamic>? ?? const [])) {
          final sym = _symptomFrom(s.toString());
          if (sym != null) symptoms.add(sym);
        }
        return VomitRecord(
          id: id,
          timestamp: ts,
          kind: _vomitKindFrom(json['vomit_kind'] as String?),
          amount: _vomitAmountFrom(json['vomit_amount'] as String?),
          symptoms: symptoms,
          colorNote: json['color_note'] as String?,
        );
      case 'sleep':
        return SleepRecord(
          id: id,
          timestamp: ts,
          duration: Duration(seconds: (json['duration_seconds'] as num?)?.toInt() ?? 0),
          dayNight: _dayNightFrom(json['day_night'] as String?),
          quality: (json['quality'] as num?)?.toInt() ?? 3,
        );
      case 'fever':
        return FeverRecord(
          id: id,
          timestamp: ts,
          temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
          method: _feverMethodFrom(json['fever_method'] as String?),
        );
      case 'medicine':
        return MedicineRecord(
          id: id,
          timestamp: ts,
          name: json['medicine_name'] as String? ?? '',
        );
      default:
        return null;
    }
  }
}
