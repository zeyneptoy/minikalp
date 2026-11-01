import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Shows an iOS-style (Cupertino) date picker in a rounded bottom sheet and
/// returns the chosen date, or null if cancelled. Used app-wide so every date
/// selection has the same wheel-style Cupertino look.
Future<DateTime?> showCupertinoDateSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Tarih seç',
  String cancelText = 'Vazgeç',
  String confirmText = 'Seç',
}) {
  // Clamp the initial date into the allowed range.
  var temp = initial;
  if (temp.isBefore(firstDate)) temp = firstDate;
  if (temp.isAfter(lastDate)) temp = lastDate;

  final theme = Theme.of(context);

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(cancelText),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(temp),
                    child: Text(confirmText),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: temp,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// iOS-style time-of-day picker. Returns the chosen [TimeOfDay], or null.
Future<TimeOfDay?> showCupertinoTimeSheet(
  BuildContext context, {
  TimeOfDay? initial,
  String title = 'Saat seç',
}) async {
  final now = DateTime.now();
  final start = initial ?? const TimeOfDay(hour: 9, minute: 0);
  var temp = DateTime(now.year, now.month, now.day, start.hour, start.minute);
  final theme = Theme.of(context);

  final picked = await showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(temp),
                  child: const Text('Seç'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: temp,
              onDateTimeChanged: (d) => temp = d,
            ),
          ),
        ],
      ),
    ),
  );

  if (picked == null) return null;
  return TimeOfDay(hour: picked.hour, minute: picked.minute);
}

/// iOS-style combined date + time picker. Returns the chosen [DateTime].
Future<DateTime?> showCupertinoDateTimeSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Tarih ve saat',
}) {
  var temp = initial;
  if (temp.isBefore(firstDate)) temp = firstDate;
  if (temp.isAfter(lastDate)) temp = lastDate;
  final theme = Theme.of(context);

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(temp),
                  child: const Text('Seç'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              use24hFormat: true,
              initialDateTime: temp,
              minimumDate: firstDate,
              maximumDate: lastDate,
              onDateTimeChanged: (d) => temp = d,
            ),
          ),
        ],
      ),
    ),
  );
}
