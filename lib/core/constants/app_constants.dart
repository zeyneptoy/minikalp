/// App-wide constant values.
///
/// Keep anything that might change globally (like the product name) here so it
/// can be swapped in a single place.
class AppConstants {
  AppConstants._();

  /// Temporary product name. Change this single constant to rename the app.
  static const String appName = 'MiniKalp';

  /// Default animation duration for micro interactions and theme changes.
  static const Duration themeAnimationDuration = Duration(milliseconds: 450);

  /// Standard entrance animation duration for cards.
  static const Duration entranceDuration = Duration(milliseconds: 420);
}
