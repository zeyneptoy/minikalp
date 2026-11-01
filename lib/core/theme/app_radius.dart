import 'package:flutter/widgets.dart';

/// Corner radius scale. The app uses very rounded corners everywhere.
class AppRadius {
  AppRadius._();

  /// 12 px — small inner elements.
  static const double sm = 12;

  /// 16 px — compact controls.
  static const double md = 16;

  /// 20 px — standard buttons.
  static const double button = 20;

  /// 24 px — standard cards.
  static const double card = 24;

  /// 28 px — large / hero cards and prominent buttons.
  static const double cardLarge = 28;

  /// 32 px — bottom sheet top corners.
  static const double sheet = 32;

  /// Fully rounded (pill) — chips and circular controls.
  static const double pill = 999;

  // Convenience BorderRadius getters.
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius cardLargeAll =
      BorderRadius.all(Radius.circular(cardLarge));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Rounded top corners only (used for bottom sheets).
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
}
