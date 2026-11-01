import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../api/record_mapper.dart';
import '../mock/health_mock.dart';
import '../notifications/notification_service.dart';
import '../mock/home_mock.dart';
import '../models/baby_record.dart';
import '../utils/duration_format.dart';

/// Repository of logged records, backed by the MiniKalp API.
///
/// Records are hydrated from the backend whenever the active baby changes and
/// every add/remove is written through to the server. State is updated
/// optimistically so the UI stays instant even on a slow connection.
class RecordsNotifier extends StateNotifier<List<BabyRecord>> {
  RecordsNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);
  int? get _babyId => _ref.read(currentBabyIdProvider);

  /// Maps a local record id to its backend id (so deletes can be synced).
  final Map<String, int> _remoteIds = {};

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listRecords(babyId);
      final records = <BabyRecord>[];
      _remoteIds.clear();
      for (final row in rows) {
        final map = row as Map<String, dynamic>;
        final record = RecordMapper.fromJson(map);
        if (record != null) {
          records.add(record);
          _remoteIds[record.id] = (map['id'] as num).toInt();
        }
      }
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = records;
    } catch (_) {
      // Keep whatever is already in memory on failure.
    }
  }

  /// Adds a record (optimistically) and syncs it to the backend.
  void add(BabyRecord record) {
    state = [record, ...state]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _syncAdd(record);
  }

  Future<void> _syncAdd(BabyRecord record) async {
    final babyId = _babyId;
    if (babyId == null) return;
    try {
      final created = await _api.createRecord(babyId, RecordMapper.toBody(record));
      _remoteIds[record.id] = (created['id'] as num).toInt();
    } catch (_) {
      // Left in local state; will be reconciled on the next hydrate.
    }
  }

  /// Removes a record by id (optimistically) and syncs the delete.
  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    final babyId = _babyId;
    final remoteId = _remoteIds.remove(id);
    if (babyId != null && remoteId != null) {
      _api.deleteRecord(babyId, remoteId).catchError((_) {});
    }
  }
}

/// All logged records, newest first.
final recordsProvider =
    StateNotifierProvider<RecordsNotifier, List<BabyRecord>>(
  (ref) => RecordsNotifier(ref),
);

/// Helper: is [a] on the same calendar day as [b]?
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Today's records (past only), newest first.
final todayRecordsProvider = Provider<List<BabyRecord>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(recordsProvider)
      .where((r) => _sameDay(r.timestamp, now) && !r.timestamp.isAfter(now))
      .toList();
});

/// Aggregated daily summary computed from today's records.
final dailySummaryProvider = Provider<DailySummary>((ref) {
  final records = ref.watch(todayRecordsProvider);

  var breastfeeding = 0;
  var formulaMl = 0;
  var stool = 0;
  var wet = 0;
  var sleep = Duration.zero;

  for (final r in records) {
    if (r is BreastfeedingRecord) {
      breastfeeding++;
    } else if (r is FormulaRecord) {
      formulaMl += r.ml;
    } else if (r is StoolRecord) {
      stool++;
    } else if (r is DiaperRecord) {
      if (r.kind.isWet) wet++;
    } else if (r is SleepRecord) {
      sleep += r.duration;
    }
  }

  return DailySummary(
    breastfeedingCount: breastfeeding,
    formulaMl: formulaMl,
    stoolCount: stool,
    wetDiapers: wet,
    totalSleep: DurationFormat.stat(sleep),
  );
});

/// The most recent feeding (breast or bottle) as a home-card summary, or null.
final lastFeedingProvider = Provider<LastFeedingInfo?>((ref) {
  final now = DateTime.now();
  final records = ref.watch(recordsProvider);
  for (final r in records) {
    if (r is BreastfeedingRecord) {
      return LastFeedingInfo(
        summary: '${r.side.label} meme',
        agoText: DurationFormat.ago(now.difference(r.timestamp)),
      );
    }
    if (r is FormulaRecord) {
      return LastFeedingInfo(
        summary: '${r.milkType.label} · ${r.ml} ml',
        agoText: DurationFormat.ago(now.difference(r.timestamp)),
      );
    }
  }
  return null;
});

/// Expressed (pumped) milk stock in millilitres, synced to the backend.
class ExpressedMilkNotifier extends StateNotifier<int> {
  ExpressedMilkNotifier(this._ref) : super(0) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      state = await _api.getExpressedMilk(babyId);
    } catch (_) {/* keep local */}
  }

  /// Sets an absolute stock value.
  void set(int value) {
    final next = value < 0 ? 0 : value;
    state = next;
    final babyId = _ref.read(currentBabyIdProvider);
    if (babyId != null) {
      _api.setExpressedMilk(babyId, stockMl: next).catchError((_) => next);
    }
  }

  /// Applies a relative change (e.g. +10 / -10 ml).
  void adjust(int delta) => set(state + delta);
}

final expressedMilkStockProvider =
    StateNotifierProvider<ExpressedMilkNotifier, int>(
  (ref) => ExpressedMilkNotifier(ref),
);

/// Editable list of medicine / vitamin reminders, synced to the backend.
class MedicineRemindersNotifier extends StateNotifier<List<MedicineReminder>> {
  MedicineRemindersNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);
  int? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listReminders(babyId);
      state = rows.map((row) => _fromJson(row as Map<String, dynamic>)).toList();
    } catch (_) {/* keep local */}
  }

  MedicineReminder _fromJson(Map<String, dynamic> json) => MedicineReminder(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        scheduleLabel: json['schedule_label'] as String? ?? 'Her gün',
        done: json['done'] as bool? ?? false,
        remindAt: json['remind_at'] as String?,
        notify: json['notify'] as bool? ?? false,
      );

  void toggle(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(done: !r.done) else r,
    ];
    final babyId = _babyId;
    final remoteId = int.tryParse(id);
    if (babyId != null && remoteId != null) {
      _api.toggleReminder(babyId, remoteId).catchError((e) => <String, dynamic>{});
    }
  }

  /// Adds a reminder; if [notify] and [remindAt] ("HH:mm") are set, schedules a
  /// daily local notification at that time.
  Future<void> addReminder(
    String name, {
    String scheduleLabel = 'Her gün',
    String? remindAt,
    bool notify = false,
  }) async {
    final babyId = _babyId;
    if (babyId == null) {
      throw StateError('Aktif bebek profili bulunamadı.');
    }

    // Let API errors propagate so the form can surface them.
    final created = await _api.createReminder(babyId, {
      'name': name,
      'schedule_label': scheduleLabel,
      if (remindAt != null) 'remind_at': remindAt,
      'notify': notify,
    });
    final entry = _fromJson(created);
    state = [entry, ...state];

    if (notify && remindAt != null && remindAt.contains(':')) {
      try {
        final granted = await NotificationService.requestPermission();
        if (granted) {
          final parts = remindAt.split(':');
          await NotificationService.scheduleDaily(
            NotificationService.medicineId(int.parse(entry.id)),
            int.tryParse(parts[0]) ?? 9,
            int.tryParse(parts[1]) ?? 0,
            'İlaç / Vitamin hatırlatıcısı',
            '$name zamanı geldi.',
          );
        }
      } catch (_) {/* notification is best-effort */}
    }
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    final babyId = _babyId;
    final remoteId = int.tryParse(id);
    if (babyId != null && remoteId != null) {
      await NotificationService.cancel(NotificationService.medicineId(remoteId));
      _api.deleteReminder(babyId, remoteId).catchError((_) {});
    }
  }
}

final medicineRemindersProvider =
    StateNotifierProvider<MedicineRemindersNotifier, List<MedicineReminder>>(
  (ref) => MedicineRemindersNotifier(ref),
);
