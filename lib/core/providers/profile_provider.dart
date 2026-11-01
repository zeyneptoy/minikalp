import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../models/baby_profile.dart';
import '../theme/theme_provider.dart';

/// Holds the committed (saved) baby profile, or null if none exists yet.
///
/// Loads from [ProfileRepository] on creation and keeps the global
/// [genderProvider] (which drives the app theme) in sync with the profile.
class BabyProfileNotifier extends StateNotifier<BabyProfile?> {
  BabyProfileNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final profile = await ProfileRepository.load();
    if (profile != null) {
      state = profile;
      _syncGender(profile.gender);
    }
  }

  /// Persists [profile], updates state and syncs the theme gender.
  Future<void> save(BabyProfile profile) async {
    await ProfileRepository.save(profile);
    state = profile;
    _syncGender(profile.gender);
  }

  /// Clears the saved profile (e.g. for a future reset action).
  Future<void> clear() async {
    await ProfileRepository.clear();
    state = null;
  }

  void _syncGender(Gender gender) {
    _ref.read(genderProvider.notifier).setGender(gender);
  }
}

/// The current saved baby profile (null until onboarding completes).
final babyProfileProvider =
    StateNotifierProvider<BabyProfileNotifier, BabyProfile?>(
  (ref) => BabyProfileNotifier(ref),
);

/// Mutable draft used by the step-by-step profile form.
///
/// Fields are nullable/empty until the user fills them, so the form can be
/// reused both for creation and (later) for editing an existing profile.
class ProfileDraft {
  const ProfileDraft({
    this.name = '',
    this.birthDate,
    this.gender,
    this.photoPath,
  });

  final String name;
  final DateTime? birthDate;
  final Gender? gender;
  final String? photoPath;

  bool get isNameValid => name.trim().isNotEmpty;
  bool get isBirthDateValid => birthDate != null;
  bool get isGenderValid => gender != null;

  ProfileDraft copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return ProfileDraft(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  /// Seeds a draft from an existing profile (for the future edit flow).
  factory ProfileDraft.fromProfile(BabyProfile profile) => ProfileDraft(
        name: profile.name,
        birthDate: profile.birthDate,
        gender: profile.gender,
        photoPath: profile.photoPath,
      );

  /// Builds a concrete [BabyProfile]. Caller must ensure required fields are
  /// valid (name + birth date + gender).
  BabyProfile toProfile() => BabyProfile(
        name: name.trim(),
        birthDate: birthDate!,
        gender: gender ?? Gender.unspecified,
        photoPath: photoPath,
      );
}

/// Drives the multi-step profile form. Reused by create and (later) edit.
class ProfileDraftNotifier extends StateNotifier<ProfileDraft> {
  ProfileDraftNotifier() : super(const ProfileDraft());

  void setName(String name) => state = state.copyWith(name: name);

  void setBirthDate(DateTime date) => state = state.copyWith(birthDate: date);

  void setGender(Gender gender) => state = state.copyWith(gender: gender);

  void setPhoto(String path) => state = state.copyWith(photoPath: path);

  void clearPhoto() => state = state.copyWith(clearPhoto: true);

  /// Resets to an empty draft (call when starting a fresh creation flow).
  void reset() => state = const ProfileDraft();

  /// Seeds the draft from an existing profile (edit flow).
  void seed(BabyProfile profile) =>
      state = ProfileDraft.fromProfile(profile);
}

/// The in-progress profile draft.
final profileDraftProvider =
    StateNotifierProvider<ProfileDraftNotifier, ProfileDraft>(
  (ref) => ProfileDraftNotifier(),
);
