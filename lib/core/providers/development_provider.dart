import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../models/growth_measurement.dart';
import '../utils/age_calculator.dart';
import 'profile_provider.dart';

/// Latest growth measurements (prototype, in metric; display may convert).
class GrowthMeasurements {
  const GrowthMeasurements({
    this.weightKg = 5.8,
    this.heightCm = 60.0,
    this.headCm = 40.0,
  });

  final double weightKg;
  final double heightCm;
  final double headCm;

  GrowthMeasurements copyWith({
    double? weightKg,
    double? heightCm,
    double? headCm,
  }) =>
      GrowthMeasurements(
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        headCm: headCm ?? this.headCm,
      );
}

/// Growth state hydrated from the latest backend measurement; each edit posts
/// a new measurement so the history (and WHO chart point) stays in sync.
class GrowthNotifier extends StateNotifier<GrowthMeasurements> {
  GrowthNotifier(this._ref) : super(const GrowthMeasurements()) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final latest = await _api.latestGrowth(babyId);
      if (latest != null) {
        state = GrowthMeasurements(
          weightKg: (latest['weight_kg'] as num?)?.toDouble() ?? state.weightKg,
          heightCm: (latest['height_cm'] as num?)?.toDouble() ?? state.heightCm,
          headCm: (latest['head_cm'] as num?)?.toDouble() ?? state.headCm,
        );
      }
    } catch (_) {/* keep defaults */}
  }

  void setWeight(double v) => _update(state.copyWith(weightKg: v));
  void setHeight(double v) => _update(state.copyWith(heightCm: v));
  void setHead(double v) => _update(state.copyWith(headCm: v));

  void _update(GrowthMeasurements next) {
    state = next;
    final babyId = _ref.read(currentBabyIdProvider);
    if (babyId != null) {
      _api.createGrowth(babyId, {
        'weight_kg': next.weightKg,
        'height_cm': next.heightCm,
        'head_cm': next.headCm,
      }).catchError((_) => <String, dynamic>{});
    }
  }

  /// Updates the displayed latest values WITHOUT posting (used after the
  /// monthly history form has already saved a measurement).
  void applyLatest(double weightKg, double heightCm, double headCm) {
    state = GrowthMeasurements(
      weightKg: weightKg,
      heightCm: heightCm,
      headCm: headCm,
    );
  }
}

final growthProvider =
    StateNotifierProvider<GrowthNotifier, GrowthMeasurements>(
  (ref) => GrowthNotifier(ref),
);

/// Full history of growth measurements for the active baby (newest first).
class GrowthHistoryNotifier extends StateNotifier<List<GrowthMeasurement>> {
  GrowthHistoryNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listGrowth(babyId);
      state = rows
          .map((e) => GrowthMeasurement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {/* keep local */}
  }

  Future<void> add({
    required double weightKg,
    required double heightCm,
    required double headCm,
    required DateTime measuredAt,
  }) async {
    // Optimistic insert so the list updates immediately.
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final temp = GrowthMeasurement(
      id: tempId,
      weightKg: weightKg,
      heightCm: heightCm,
      headCm: headCm,
      measuredAt: measuredAt,
    );
    state = [temp, ...state]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    final babyId = _ref.read(currentBabyIdProvider);
    if (babyId == null) return;
    try {
      final created = await _api.createGrowth(babyId, {
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'head_cm': headCm,
        'measured_at': measuredAt.toIso8601String(),
      });
      final m = GrowthMeasurement.fromJson(created);
      state = [
        for (final e in state) if (e.id == tempId) m else e,
      ]..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    } catch (_) {/* keep optimistic entry */}
  }
}

final growthHistoryProvider =
    StateNotifierProvider<GrowthHistoryNotifier, List<GrowthMeasurement>>(
  (ref) => GrowthHistoryNotifier(ref),
);

/// Checked milestones, keyed as "month:index".
class MilestoneCheckNotifier extends StateNotifier<Set<String>> {
  MilestoneCheckNotifier(this._ref) : super(<String>{}) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final keys = await _api.getMilestones(babyId);
      state = keys.map((e) => e.toString()).toSet();
    } catch (_) {/* keep local */}
  }

  void toggle(String key) {
    final next = {...state};
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = next;

    final babyId = _ref.read(currentBabyIdProvider);
    if (babyId != null) {
      _api.toggleMilestone(babyId, key).then((keys) {
        state = keys.map((e) => e.toString()).toSet();
      }).catchError((_) {});
    }
  }

  bool isChecked(String key) => state.contains(key);
}

final milestoneCheckProvider =
    StateNotifierProvider<MilestoneCheckNotifier, Set<String>>(
  (ref) => MilestoneCheckNotifier(ref),
);

/// Erupted teeth indices (0–19) for the simple tooth chart.
class TeethNotifier extends StateNotifier<Set<int>> {
  TeethNotifier(this._ref) : super(<int>{}) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final indices = await _api.getTeeth(babyId);
      state = indices.map((e) => (e as num).toInt()).toSet();
    } catch (_) {/* keep local */}
  }

  void toggle(int index) {
    final next = {...state};
    if (next.contains(index)) {
      next.remove(index);
    } else {
      next.add(index);
    }
    state = next;

    final babyId = _ref.read(currentBabyIdProvider);
    if (babyId != null) {
      _api.toggleTooth(babyId, index).then((indices) {
        state = indices.map((e) => (e as num).toInt()).toSet();
      }).catchError((_) {});
    }
  }
}

final teethProvider =
    StateNotifierProvider<TeethNotifier, Set<int>>((ref) => TeethNotifier(ref));

/// A "first" memory milestone (ilk gülümseme, ilk adım, …).
class FirstMemory {
  const FirstMemory({required this.title, this.photoPath, this.remoteId});
  final String title;
  final String? photoPath;

  /// Backend memory id, once hydrated.
  final int? remoteId;

  FirstMemory copyWith({String? photoPath, int? remoteId}) => FirstMemory(
        title: title,
        photoPath: photoPath ?? this.photoPath,
        remoteId: remoteId ?? this.remoteId,
      );
}

class FirstsNotifier extends StateNotifier<List<FirstMemory>> {
  FirstsNotifier(this._ref)
      : super(const [
          FirstMemory(title: 'İlk gülümseme'),
          FirstMemory(title: 'İlk diş'),
          FirstMemory(title: 'İlk oturma'),
          FirstMemory(title: 'İlk emekleme'),
          FirstMemory(title: 'İlk kelime'),
          FirstMemory(title: 'İlk adım'),
        ]) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listMemories(babyId);
      if (rows.isEmpty) return;
      state = rows.map((row) {
        final m = row as Map<String, dynamic>;
        return FirstMemory(
          title: m['title'] as String? ?? '',
          photoPath: m['photo_path'] as String?,
          remoteId: (m['id'] as num?)?.toInt(),
        );
      }).toList();
    } catch (_) {/* keep defaults */}
  }

  void setPhoto(int index, String path) {
    final list = [...state];
    list[index] = list[index].copyWith(photoPath: path);
    state = list;

    final babyId = _ref.read(currentBabyIdProvider);
    final remoteId = list[index].remoteId;
    if (babyId != null && remoteId != null) {
      _api.updateMemory(babyId, remoteId, {'photo_path': path})
          .catchError((_) => <String, dynamic>{});
    }
  }
}

final firstsProvider =
    StateNotifierProvider<FirstsNotifier, List<FirstMemory>>(
  (ref) => FirstsNotifier(ref),
);

/// Free-form photo album (local file paths).
class AlbumNotifier extends StateNotifier<List<String>> {
  AlbumNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listPhotos(babyId);
      state = rows
          .map((row) => (row as Map<String, dynamic>)['path'] as String)
          .toList();
    } catch (_) {/* keep local */}
  }

  void add(String path) {
    state = [path, ...state];
    final babyId = _ref.read(currentBabyIdProvider);
    if (babyId != null) {
      // Tag the photo with the baby's current month using the SAME calculation
      // the month browser uses, so it shows up under the right month.
      final body = <String, dynamic>{'path': path};
      final profile = _ref.read(babyProfileProvider);
      if (profile != null) {
        final m = AgeCalculator.calculate(profile.birthDate).months.clamp(0, 11);
        body['month'] = m;
      }
      _api.createPhoto(babyId, body).catchError((_) => <String, dynamic>{});
    }
  }
}

final albumProvider =
    StateNotifierProvider<AlbumNotifier, List<String>>(
  (ref) => AlbumNotifier(ref),
);

/// Mother's mood diary (simple 1–5 scale entries with an optional note).
class MoodEntry {
  const MoodEntry({required this.score, required this.timestamp, this.note});
  final int score;
  final DateTime timestamp;
  final String? note;
}

class MoodNotifier extends StateNotifier<List<MoodEntry>> {
  MoodNotifier(this._ref) : super(const []) {
    // Mood is per-user; hydrate once the API client is ready (reuse the baby
    // signal as a convenient "we're authenticated now" trigger).
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate();
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _hydrate() async {
    try {
      final rows = await _api.listMood();
      state = rows.map((row) {
        final m = row as Map<String, dynamic>;
        return MoodEntry(
          score: (m['score'] as num?)?.toInt() ?? 3,
          timestamp:
              DateTime.tryParse(m['recorded_at'] as String? ?? '') ?? DateTime.now(),
          note: m['note'] as String?,
        );
      }).toList();
    } catch (_) {/* keep local */}
  }

  void add(int score, {String? note}) {
    state = [
      MoodEntry(score: score, timestamp: DateTime.now(), note: note),
      ...state,
    ];
    _api.createMood({'score': score, if (note != null) 'note': note})
        .catchError((_) => <String, dynamic>{});
  }
}

final moodProvider =
    StateNotifierProvider<MoodNotifier, List<MoodEntry>>((ref) => MoodNotifier(ref));
