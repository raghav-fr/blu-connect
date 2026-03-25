import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile_model.dart';

class ProfileService extends ChangeNotifier {
  UserProfile _profile = UserProfile(id: const Uuid().v4());
  final ImagePicker _picker = ImagePicker();
  bool _isLoaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;
  bool get isProfileSetup => _profile.isSetup;

  ProfileService() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('profile_id');

    if (id != null) {
      final map = <String, String>{};
      for (final key in [
        'id', 'name', 'role', 'age', 'gender',
        'bloodGroup', 'medicalNote', 'avatarPath', 'visibility'
      ]) {
        map[key] = prefs.getString('profile_$key') ?? '';
      }
      _profile = UserProfile.fromStorageMap(map);
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    final map = profile.toStorageMap();
    for (final entry in map.entries) {
      await prefs.setString('profile_${entry.key}', entry.value);
    }
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    await saveProfile(_profile.copyWith(name: name));
  }

  Future<void> updateRole(String role) async {
    await saveProfile(_profile.copyWith(role: role));
  }

  Future<void> updateBloodGroup(String bloodGroup) async {
    await saveProfile(_profile.copyWith(bloodGroup: bloodGroup));
  }

  Future<void> updateMedicalNote(String note) async {
    await saveProfile(_profile.copyWith(medicalNote: note));
  }

  Future<void> updateAge(int? age) async {
    await saveProfile(_profile.copyWith(age: age));
  }

  Future<void> updateGender(String? gender) async {
    await saveProfile(_profile.copyWith(gender: gender));
  }

  Future<void> updateVisibility(ProfileVisibility visibility) async {
    await saveProfile(_profile.copyWith(visibility: visibility));
  }

  Future<void> pickAvatarFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        await _saveAvatar(image);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> pickAvatarFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        await _saveAvatar(image);
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

  Future<void> _saveAvatar(XFile image) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(p.join(dir.path, 'avatars'));
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final ext = p.extension(image.path);
    final destPath = p.join(avatarDir.path, 'avatar$ext');

    // Delete old avatar if exists
    if (_profile.avatarPath != null) {
      final oldFile = File(_profile.avatarPath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    await File(image.path).copy(destPath);
    await saveProfile(_profile.copyWith(avatarPath: destPath));
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('profile_'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }

    if (_profile.avatarPath != null) {
      final file = File(_profile.avatarPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _profile = UserProfile(id: const Uuid().v4());
    notifyListeners();
  }
}
