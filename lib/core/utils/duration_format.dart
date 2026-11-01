/// Turkish duration formatting helpers shared across tracking and home.
class DurationFormat {
  DurationFormat._();

  /// Compact "saat / dakika" label, e.g. "1 sa 20 dk", "18 dk", "2 sa".
  static String hm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '$m dk';
    if (m == 0) return '$h sa';
    return '$h sa $m dk';
  }

  /// Short stat label used in summary chips, e.g. "14s 20dk", "40dk".
  static String stat(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '${m}dk';
    return '${h}s ${m}dk';
  }

  /// "mm:ss" for a live timer display.
  static String clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  /// "x önce" phrasing from a past duration, e.g. "1 sa 20 dk önce".
  static String ago(Duration d) {
    if (d.inMinutes < 1) return 'az önce';
    return '${hm(d)} önce';
  }
}
