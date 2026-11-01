import 'package:flutter/material.dart';

import '../utils/duration_format.dart';

// ---------------------------------------------------------------------------
// Enums shared by the tracking forms
// ---------------------------------------------------------------------------

/// Which breast was used for a breastfeeding session.
enum BreastSide { left, right, both }

extension BreastSideLabel on BreastSide {
  String get label {
    switch (this) {
      case BreastSide.left:
        return 'Sol';
      case BreastSide.right:
        return 'Sağ';
      case BreastSide.both:
        return 'İkisi';
    }
  }
}

/// Milk type for a bottle feeding.
enum MilkType { breastMilk, formula }

extension MilkTypeLabel on MilkType {
  String get label =>
      this == MilkType.breastMilk ? 'Anne sütü' : 'Formül';
}

/// Baby's reaction to a newly introduced solid food.
enum SolidReaction { none, rash, vomit, stoolChange }

extension SolidReactionLabel on SolidReaction {
  String get label {
    switch (this) {
      case SolidReaction.none:
        return 'Yok';
      case SolidReaction.rash:
        return 'Döküntü';
      case SolidReaction.vomit:
        return 'Kusma';
      case SolidReaction.stoolChange:
        return 'Kaka değişimi';
    }
  }
}

/// Stool color options, each with a swatch color, a short info note and
/// whether it is clinically notable ("critical").
enum StoolColor { yellow, green, brown, black, red, whiteGray }

extension StoolColorInfo on StoolColor {
  String get label {
    switch (this) {
      case StoolColor.yellow:
        return 'Sarı';
      case StoolColor.green:
        return 'Yeşil';
      case StoolColor.brown:
        return 'Kahverengi';
      case StoolColor.black:
        return 'Siyah';
      case StoolColor.red:
        return 'Kırmızı';
      case StoolColor.whiteGray:
        return 'Beyaz/Gri';
    }
  }

  /// Swatch color used by the picker circles.
  Color get swatch {
    switch (this) {
      case StoolColor.yellow:
        return const Color(0xFFF2C94C);
      case StoolColor.green:
        return const Color(0xFF6FB76F);
      case StoolColor.brown:
        return const Color(0xFF9B6A43);
      case StoolColor.black:
        return const Color(0xFF3A3A3A);
      case StoolColor.red:
        return const Color(0xFFD1584E);
      case StoolColor.whiteGray:
        return const Color(0xFFDADDE0);
    }
  }

  /// Short explanatory note shown when the color is tapped.
  String get info {
    switch (this) {
      case StoolColor.yellow:
        return 'Anne sütü alan bebeklerde en sık görülen normal renktir.';
      case StoolColor.green:
        return 'Çoğu zaman normaldir; beslenmeye veya sindirime bağlı olabilir.';
      case StoolColor.brown:
        return 'Ek gıdaya geçişte sık görülen normal bir renktir.';
      case StoolColor.black:
        return 'Yenidoğan ilk günler dışında dikkat gerektirebilir.';
      case StoolColor.red:
        return 'Kan izi olabilir; değerlendirilmesi önerilir.';
      case StoolColor.whiteGray:
        return 'Nadir görülür ve değerlendirilmesi önemlidir.';
    }
  }

  /// Colors that warrant a gentle "doktorunuza danışın" note.
  bool get isCritical =>
      this == StoolColor.whiteGray ||
      this == StoolColor.red ||
      this == StoolColor.black;
}

/// Stool consistency options.
enum StoolConsistency { watery, soft, normal, hard, lumpy }

extension StoolConsistencyLabel on StoolConsistency {
  String get label {
    switch (this) {
      case StoolConsistency.watery:
        return 'Sulu';
      case StoolConsistency.soft:
        return 'Yumuşak';
      case StoolConsistency.normal:
        return 'Normal';
      case StoolConsistency.hard:
        return 'Sert';
      case StoolConsistency.lumpy:
        return 'Topak topak';
    }
  }
}

/// Diaper contents for the diaper counter / quick log.
enum DiaperKind { wet, dirty, both }

extension DiaperKindLabel on DiaperKind {
  String get label {
    switch (this) {
      case DiaperKind.wet:
        return 'Islak';
      case DiaperKind.dirty:
        return 'Kirli';
      case DiaperKind.both:
        return 'İkisi';
    }
  }

  bool get isWet => this == DiaperKind.wet || this == DiaperKind.both;
  bool get isDirty => this == DiaperKind.dirty || this == DiaperKind.both;
}

/// Type of vomiting episode.
enum VomitKind { spitUp, forceful }

extension VomitKindLabel on VomitKind {
  String get label =>
      this == VomitKind.spitUp ? 'Geri çıkarma' : 'Fışkırtarak kusma';
}

/// Approximate amount for a vomiting episode.
enum VomitAmount { low, medium, high }

extension VomitAmountLabel on VomitAmount {
  String get label {
    switch (this) {
      case VomitAmount.low:
        return 'Az';
      case VomitAmount.medium:
        return 'Orta';
      case VomitAmount.high:
        return 'Çok';
    }
  }
}

/// Accompanying symptoms for vomiting (multi-select).
enum VomitSymptom { fever, restlessness, fatigue }

extension VomitSymptomLabel on VomitSymptom {
  String get label {
    switch (this) {
      case VomitSymptom.fever:
        return 'Ateş';
      case VomitSymptom.restlessness:
        return 'Huzursuzluk';
      case VomitSymptom.fatigue:
        return 'Halsizlik';
    }
  }
}

/// Whether a sleep happened during the day or at night.
enum DayNight { day, night }

extension DayNightLabel on DayNight {
  String get label => this == DayNight.day ? 'Gündüz' : 'Gece';
}

/// Where the temperature was measured.
enum FeverMethod { armpit, ear, forehead, mouth }

extension FeverMethodLabel on FeverMethod {
  String get label {
    switch (this) {
      case FeverMethod.armpit:
        return 'Koltuk altı';
      case FeverMethod.ear:
        return 'Kulak';
      case FeverMethod.forehead:
        return 'Alın';
      case FeverMethod.mouth:
        return 'Ağız';
    }
  }
}

// ---------------------------------------------------------------------------
// Record hierarchy
// ---------------------------------------------------------------------------

/// Base class for a single logged record. Every record exposes an icon, title
/// and detail so the home timeline can render it without knowing its concrete
/// type. Concrete kinds are matched with `is` checks for summary aggregation.
abstract class BabyRecord {
  BabyRecord({String? id, DateTime? timestamp})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  final String id;
  final DateTime timestamp;

  IconData get icon;
  String get title;
  String get detail;
}

/// A breastfeeding session.
class BreastfeedingRecord extends BabyRecord {
  BreastfeedingRecord({
    required this.side,
    required this.duration,
    super.id,
    super.timestamp,
  });

  final BreastSide side;
  final Duration duration;

  @override
  IconData get icon => Icons.local_drink_rounded;
  @override
  String get title => 'Emzirme';
  @override
  String get detail => '${side.label} meme · ${DurationFormat.hm(duration)}';
}

/// A bottle feeding (expressed milk or formula).
class FormulaRecord extends BabyRecord {
  FormulaRecord({
    required this.milkType,
    required this.ml,
    super.id,
    super.timestamp,
  });

  final MilkType milkType;
  final int ml;

  @override
  IconData get icon => Icons.local_cafe_rounded;
  @override
  String get title => 'Mama';
  @override
  String get detail => '${milkType.label} · $ml ml';
}

/// A newly introduced solid food (6+ months).
class SolidFoodRecord extends BabyRecord {
  SolidFoodRecord({
    required this.foodName,
    required this.reaction,
    super.id,
    super.timestamp,
  });

  final String foodName;
  final SolidReaction reaction;

  @override
  IconData get icon => Icons.restaurant_rounded;
  @override
  String get title => 'Ek gıda';
  @override
  String get detail => '$foodName · Tepki: ${reaction.label}';
}

/// A stool record.
class StoolRecord extends BabyRecord {
  StoolRecord({
    required this.color,
    required this.consistency,
    this.note,
    this.photoPath,
    super.id,
    super.timestamp,
  });

  final StoolColor color;
  final StoolConsistency consistency;
  final String? note;
  final String? photoPath;

  @override
  IconData get icon => Icons.wc_rounded;
  @override
  String get title => 'Kaka';
  @override
  String get detail => '${color.label} · ${consistency.label}';
}

/// A diaper change (wet / dirty).
class DiaperRecord extends BabyRecord {
  DiaperRecord({required this.kind, super.id, super.timestamp});

  final DiaperKind kind;

  @override
  IconData get icon => Icons.baby_changing_station_rounded;
  @override
  String get title => 'Bez';
  @override
  String get detail => kind.label;
}

/// A vomiting episode.
class VomitRecord extends BabyRecord {
  VomitRecord({
    required this.kind,
    required this.amount,
    required this.symptoms,
    this.colorNote,
    super.id,
    super.timestamp,
  });

  final VomitKind kind;
  final VomitAmount amount;
  final Set<VomitSymptom> symptoms;
  final String? colorNote;

  @override
  IconData get icon => Icons.sick_rounded;
  @override
  String get title => 'Kusma';
  @override
  String get detail => '${kind.label} · ${amount.label}';
}

/// A sleep session.
class SleepRecord extends BabyRecord {
  SleepRecord({
    required this.duration,
    required this.dayNight,
    required this.quality,
    super.id,
    super.timestamp,
  });

  final Duration duration;
  final DayNight dayNight;

  /// 1–5 rating.
  final int quality;

  @override
  IconData get icon => Icons.bedtime_rounded;
  @override
  String get title => 'Uyku';
  @override
  String get detail =>
      '${dayNight.label} · ${DurationFormat.hm(duration)} · $quality/5';
}

/// A fever / temperature measurement.
class FeverRecord extends BabyRecord {
  FeverRecord({
    required this.temperature,
    required this.method,
    super.id,
    super.timestamp,
  });

  final double temperature;
  final FeverMethod method;

  @override
  IconData get icon => Icons.thermostat_rounded;
  @override
  String get title => 'Ateş';
  @override
  String get detail =>
      '${temperature.toStringAsFixed(1)}°C · ${method.label}';
}

/// A medicine / vitamin dose log.
class MedicineRecord extends BabyRecord {
  MedicineRecord({required this.name, super.id, super.timestamp});

  final String name;

  @override
  IconData get icon => Icons.medication_rounded;
  @override
  String get title => 'İlaç/Vitamin';
  @override
  String get detail => name;
}
