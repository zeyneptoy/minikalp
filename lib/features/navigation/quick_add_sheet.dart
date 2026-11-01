import 'package:flutter/material.dart';

import '../../core/models/record_type.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

/// A glass bottom sheet presenting a grid of record types for quick logging.
///
/// Returns the chosen [RecordType] (or null if dismissed). The record forms
/// themselves arrive in a later round.
class QuickAddSheet {
  QuickAddSheet._();

  /// All record types offered in the quick-add grid.
  static const List<RecordType> types = RecordType.values;

  /// Shows the sheet and resolves with the selected type.
  static Future<RecordType?> show(BuildContext context) {
    return GlassBottomSheet.show<RecordType>(
      context,
      title: 'Hızlı Kayıt',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: types.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          // Hug the tile content so cells don't overflow (no RenderFlex error).
          mainAxisExtent: 104,
        ),
        itemBuilder: (context, i) => QuickActionTile(
          icon: types[i].icon,
          label: types[i].label,
          onTap: () => Navigator.of(context).pop(types[i]),
        ),
      ),
    );
  }
}
