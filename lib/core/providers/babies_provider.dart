import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../data/profile_repository.dart';
import '../models/baby_profile.dart';
import 'profile_provider.dart';

/// Immutable state for the multi-baby store.
class BabiesState {
  const BabiesState({required this.babies, required this.activeIndex});

  final List<BabyProfile> babies;
  final int activeIndex;

  /// The currently active baby, or null when none exist yet.
  BabyProfile? get active {
    if (babies.isEmpty) return null;
    return babies[activeIndex.clamp(0, babies.length - 1)];
  }

  BabiesState copyWith({List<BabyProfile>? babies, int? activeIndex}) =>
      BabiesState(
        babies: babies ?? this.babies,
        activeIndex: activeIndex ?? this.activeIndex,
      );
}

/// Owns the list of babies and the active selection, and keeps the single
/// [babyProfileProvider] (used across the app) in sync with the active baby —
/// which also drives the gender theme. Persisted locally via
/// [ProfileRepository] and mirrored to the backend (each baby gets a
/// [BabyProfile.remoteId] once created on the server).
class BabiesNotifier extends StateNotifier<BabiesState> {
  BabiesNotifier(this._ref)
      : super(const BabiesState(babies: [], activeIndex: 0)) {
    _load();
  }

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> _load() async {
    var babies = await ProfileRepository.loadBabies();
    // Migrate a legacy single profile (from earlier rounds) into the list.
    if (babies.isEmpty) {
      final legacy = await ProfileRepository.load();
      if (legacy != null) {
        babies = [legacy];
        await ProfileRepository.saveBabies(babies);
      }
    }
    final index = await ProfileRepository.loadActiveIndex();

    // Guard: if the user already added a baby while this async load was in
    // flight, don't clobber their change.
    if (state.babies.isNotEmpty) return;

    state = BabiesState(
      babies: babies,
      activeIndex: babies.isEmpty ? 0 : index.clamp(0, babies.length - 1),
    );
    _syncActive();

    // Make sure the active baby exists on the backend (legacy / offline-created
    // profiles may not have a remoteId yet).
    _ensureActiveRemote();
  }

  /// Adds a new baby and makes it active, creating it on the backend.
  Future<void> addBaby(BabyProfile profile) async {
    final babies = [...state.babies, profile];
    state = BabiesState(babies: babies, activeIndex: babies.length - 1);
    await _persist();
    _syncActive();
    await _ensureActiveRemote();
  }

  /// Replaces the active baby (used by the edit flow).
  Future<void> updateActive(BabyProfile profile) async {
    if (state.babies.isEmpty) {
      await addBaby(profile);
      return;
    }
    final existing = state.babies[state.activeIndex];
    // Preserve the backend id across an edit.
    final merged = profile.copyWith(remoteId: existing.remoteId);
    final babies = [...state.babies];
    babies[state.activeIndex] = merged;
    state = state.copyWith(babies: babies);
    await _persist();
    _syncActive();

    if (merged.remoteId != null) {
      try {
        await _api.updateBaby(merged.remoteId!, _babyBody(merged));
      } catch (_) {
        // Keep the local edit even if the sync fails.
      }
    } else {
      await _ensureActiveRemote();
    }
  }

  /// Switches the active baby by index.
  Future<void> setActive(int index) async {
    if (index < 0 || index >= state.babies.length) return;
    state = state.copyWith(activeIndex: index);
    await _persist();
    _syncActive();
    await _ensureActiveRemote();
  }

  /// Re-attempts backend creation for the active baby (e.g. after the server
  /// address changed or connectivity was restored).
  Future<void> retrySync() => _ensureActiveRemote();

  /// Creates the active baby on the backend if it has no [remoteId] yet, then
  /// stores the returned id so data syncing can begin.
  Future<void> _ensureActiveRemote() async {
    final active = state.active;
    if (active == null || active.remoteId != null) return;

    try {
      final created = await _api.createBaby(_babyBody(active));
      final id = (created['id'] as num).toInt();
      final updated = active.copyWith(remoteId: id);

      final babies = [...state.babies];
      babies[state.activeIndex] = updated;
      state = state.copyWith(babies: babies);
      await _persist();
      _syncActive();
    } catch (_) {
      // Offline or server down: the app keeps working locally and will retry
      // the next time the active baby changes.
    }
  }

  Map<String, dynamic> _babyBody(BabyProfile p) => {
        'name': p.name,
        'birth_date': p.birthDate.toIso8601String().substring(0, 10),
        'gender': p.gender.storageKey,
        if (p.photoPath != null) 'photo_path': p.photoPath,
      };

  Future<void> _persist() async {
    await ProfileRepository.saveBabies(state.babies);
    await ProfileRepository.saveActiveIndex(state.activeIndex);
  }

  /// Pushes the active baby into [babyProfileProvider] (also persists it as the
  /// legacy single profile and updates the gender theme).
  void _syncActive() {
    final active = state.active;
    if (active != null) {
      _ref.read(babyProfileProvider.notifier).save(active);
    }
  }
}

/// The multi-baby store.
final babiesProvider = StateNotifierProvider<BabiesNotifier, BabiesState>(
  (ref) => BabiesNotifier(ref),
);
