/// Spacing scale used across the whole app.
///
/// Never hardcode paddings or gaps in widgets; always pull from this scale so
/// the layout rhythm stays consistent.
class AppSpacing {
  AppSpacing._();

  /// 4 px — hairline gaps between tightly related elements.
  static const double xs = 4;

  /// 8 px — small gaps (icon to label, chip internal spacing).
  static const double sm = 8;

  /// 12 px — compact spacing inside dense cards.
  static const double md = 12;

  /// 16 px — the default content padding.
  static const double lg = 16;

  /// 24 px — section spacing / generous card padding.
  static const double xl = 24;

  /// 32 px — large separations between major sections.
  static const double xxl = 32;
}
