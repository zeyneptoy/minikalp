/// The baby's gender. Drives the whole app color theme.
enum Gender {
  /// Girl -> pink palette.
  girl,

  /// Boy -> blue palette.
  boy,

  /// Not specified / not known yet -> orange palette.
  unspecified,
}

/// Turkish labels and helpers for [Gender].
extension GenderLabel on Gender {
  /// Human-readable Turkish label.
  String get label {
    switch (this) {
      case Gender.girl:
        return 'Kız';
      case Gender.boy:
        return 'Erkek';
      case Gender.unspecified:
        return 'Belirtilmedi';
    }
  }

  /// Stable key used when persisting the value.
  String get storageKey => name;

  /// Parse from a stored key, falling back to [Gender.unspecified].
  static Gender fromStorageKey(String? key) {
    return Gender.values.firstWhere(
      (g) => g.name == key,
      orElse: () => Gender.unspecified,
    );
  }
}

/// A single baby profile. This is pure UI mock data for the prototype —
/// there is no backend behind it.
class BabyProfile {
  const BabyProfile({
    required this.name,
    required this.birthDate,
    required this.gender,
    this.photoPath,
    this.remoteId,
  });

  /// Backend (Laravel) id for this baby, once it has been synced. Null until
  /// the profile has been created on the server.
  final int? remoteId;

  /// Baby's display name.
  final String name;

  /// Date of birth, used by the age calculator.
  final DateTime birthDate;

  /// Gender, which selects the active color palette.
  final Gender gender;

  /// Optional local file path to the baby's photo (from image_picker).
  final String? photoPath;

  /// Returns a copy with the given fields replaced.
  BabyProfile copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? photoPath,
    int? remoteId,
    bool clearPhoto = false,
  }) {
    return BabyProfile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      remoteId: remoteId ?? this.remoteId,
    );
  }

  /// Serializes the profile to a plain JSON map for local persistence.
  Map<String, dynamic> toJson() => {
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender.storageKey,
        'photoPath': photoPath,
        'remoteId': remoteId,
      };

  /// Rebuilds a profile from a [toJson] map. Returns null if the map is
  /// missing the required fields (e.g. corrupted storage).
  static BabyProfile? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final birthRaw = json['birthDate'] as String?;
    if (name == null || birthRaw == null) return null;
    final birthDate = DateTime.tryParse(birthRaw);
    if (birthDate == null) return null;
    return BabyProfile(
      name: name,
      birthDate: birthDate,
      gender: GenderLabel.fromStorageKey(json['gender'] as String?),
      photoPath: json['photoPath'] as String?,
      remoteId: (json['remoteId'] as num?)?.toInt(),
    );
  }
}
