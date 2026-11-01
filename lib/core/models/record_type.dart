import 'package:flutter/material.dart';

/// The kinds of records a parent can log. Shared by the home quick-record grid
/// and the quick-add bottom sheet so both stay in sync.
enum RecordType {
  breastfeeding,
  formula,
  stool,
  vomit,
  sleep,
  diaper,
  fever,
  medicine,
}

/// Turkish labels and rounded icons for [RecordType].
extension RecordTypeInfo on RecordType {
  /// Turkish display label.
  String get label {
    switch (this) {
      case RecordType.breastfeeding:
        return 'Emzirme';
      case RecordType.formula:
        return 'Mama';
      case RecordType.stool:
        return 'Kaka';
      case RecordType.vomit:
        return 'Kusma';
      case RecordType.sleep:
        return 'Uyku';
      case RecordType.diaper:
        return 'Bez';
      case RecordType.fever:
        return 'Ateş';
      case RecordType.medicine:
        return 'İlaç/Vitamin';
    }
  }

  /// Rounded icon representing the record type.
  IconData get icon {
    switch (this) {
      case RecordType.breastfeeding:
        return Icons.local_drink_rounded;
      case RecordType.formula:
        return Icons.local_cafe_rounded;
      case RecordType.stool:
        return Icons.wc_rounded;
      case RecordType.vomit:
        return Icons.sick_rounded;
      case RecordType.sleep:
        return Icons.bedtime_rounded;
      case RecordType.diaper:
        return Icons.baby_changing_station_rounded;
      case RecordType.fever:
        return Icons.thermostat_rounded;
      case RecordType.medicine:
        return Icons.medication_rounded;
    }
  }
}
