enum ProfileVisibility { public, limited, hidden }

class UserProfile {
  final String id;
  final String name;
  final String role;
  final int? age;
  final String? gender;
  final String bloodGroup;
  final String medicalNote;
  final String? avatarPath;
  final ProfileVisibility visibility;

  UserProfile({
    required this.id,
    this.name = '',
    this.role = 'Survivor',
    this.age,
    this.gender,
    this.bloodGroup = '',
    this.medicalNote = '',
    this.avatarPath,
    this.visibility = ProfileVisibility.limited,
  });

  bool get isSetup => name.isNotEmpty;

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get visibilityLabel {
    switch (visibility) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.limited:
        return 'Limited Access';
      case ProfileVisibility.hidden:
        return 'Hidden';
    }
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? role,
    int? age,
    String? gender,
    String? bloodGroup,
    String? medicalNote,
    String? avatarPath,
    ProfileVisibility? visibility,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNote: medicalNote ?? this.medicalNote,
      avatarPath: avatarPath ?? this.avatarPath,
      visibility: visibility ?? this.visibility,
    );
  }

  Map<String, String> toStorageMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'age': age?.toString() ?? '',
      'gender': gender ?? '',
      'bloodGroup': bloodGroup,
      'medicalNote': medicalNote,
      'avatarPath': avatarPath ?? '',
      'visibility': visibility.index.toString(),
    };
  }

  factory UserProfile.fromStorageMap(Map<String, String> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Survivor',
      age: map['age']?.isNotEmpty == true ? int.tryParse(map['age']!) : null,
      gender: map['gender']?.isNotEmpty == true ? map['gender'] : null,
      bloodGroup: map['bloodGroup'] ?? '',
      medicalNote: map['medicalNote'] ?? '',
      avatarPath: map['avatarPath']?.isNotEmpty == true ? map['avatarPath'] : null,
      visibility: ProfileVisibility.values[int.tryParse(map['visibility'] ?? '1') ?? 1],
    );
  }
}
