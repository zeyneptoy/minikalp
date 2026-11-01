import 'package:flutter/material.dart';

import '../../core/models/record_type.dart';
import '../../core/widgets/widgets.dart';
import 'forms/breastfeeding_form.dart';
import 'forms/diaper_form.dart';
import 'forms/fever_form.dart';
import 'forms/formula_form.dart';
import 'forms/medicine_form.dart';
import 'forms/sleep_form.dart';
import 'forms/stool_form.dart';
import 'forms/vomit_form.dart';

/// Opens the record form for a given [RecordType] as a glass bottom sheet.
///
/// The same form widgets are embedded in the tracking tab; here each is given
/// an `onSaved` that closes the sheet.
class RecordSheets {
  RecordSheets._();

  static Future<void> open(BuildContext context, RecordType type) {
    return GlassBottomSheet.show<void>(
      context,
      title: type.label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: SingleChildScrollView(
          child: _formFor(type, () => Navigator.of(context).pop()),
        ),
      ),
    );
  }

  static Widget _formFor(RecordType type, VoidCallback onSaved) {
    switch (type) {
      case RecordType.breastfeeding:
        return BreastfeedingForm(onSaved: onSaved);
      case RecordType.formula:
        return FormulaForm(onSaved: onSaved);
      case RecordType.stool:
        return StoolForm(onSaved: onSaved);
      case RecordType.vomit:
        return VomitForm(onSaved: onSaved);
      case RecordType.sleep:
        return SleepForm(onSaved: onSaved);
      case RecordType.diaper:
        return DiaperForm(onSaved: onSaved);
      case RecordType.fever:
        return FeverForm(onSaved: onSaved);
      case RecordType.medicine:
        return MedicineForm(onSaved: onSaved);
    }
  }
}
