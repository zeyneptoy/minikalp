import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../models/diary_entry.dart';

/// The mother's diary for the active baby, hydrated from the backend and
/// written through on add/remove. Entries are newest-first.
class DiaryNotifier extends StateNotifier<List<DiaryEntry>> {
  DiaryNotifier(this._ref) : super(const []) {
    _ref.listen<int?>(currentBabyIdProvider, (_, next) {
      if (next != null) _hydrate(next);
    }, fireImmediately: true);
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);
  int? get _babyId => _ref.read(currentBabyIdProvider);

  Future<void> _hydrate(int babyId) async {
    try {
      final rows = await _api.listDiary(babyId);
      state = rows
          .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {/* keep local */}
  }

  /// Adds an entry for [month] (the baby's current month). Inserts it
  /// optimistically so the UI responds immediately, then syncs to the backend.
  Future<void> add(String body, {int? month}) async {
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final temp = DiaryEntry(
      id: tempId,
      month: month ?? 0,
      body: body,
      createdAt: DateTime.now(),
    );
    state = [temp, ...state];

    final babyId = _babyId;
    if (babyId == null) return;
    try {
      final created = await _api.createDiary(babyId, body, month: month);
      final entry = DiaryEntry.fromJson(created);
      state = [for (final e in state) if (e.id == tempId) entry else e];
    } catch (_) {/* keep the optimistic entry; will re-sync on next hydrate */}
  }

  Future<void> update(int id, String body) async {
    final babyId = _babyId;
    if (babyId == null) return;
    final updated = await _api.updateDiary(babyId, id, body);
    final entry = DiaryEntry.fromJson(updated);
    state = [for (final e in state) if (e.id == id) entry else e];
  }

  Future<void> remove(int id) async {
    state = state.where((e) => e.id != id).toList();
    final babyId = _babyId;
    if (babyId != null) {
      _api.deleteDiary(babyId, id).catchError((_) {});
    }
  }
}

final diaryProvider =
    StateNotifierProvider<DiaryNotifier, List<DiaryEntry>>(
  (ref) => DiaryNotifier(ref),
);
