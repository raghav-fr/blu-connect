import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  // Connectivity
  bool _bluetoothEnabled = true;
  bool _autoDiscovery = false;
  bool _meshParticipation = true;

  // Emergency
  bool _autoSOS = false;
  bool _continuousBroadcast = false;
  int _sosIntervalSeconds = 15;

  // Privacy
  bool _encryptionEnabled = true;
  String _visibilityMode = 'limited'; // public, limited, hidden

  // Battery
  bool _powerSaveMode = true;
  int _scanIntervalSeconds = 10;

  // Mesh
  int _maxHops = 20;
  int _retryAttempts = 3;
  int _messageTTL = 30;

  // System
  String _mapRegion = 'Auto';

  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get autoDiscovery => _autoDiscovery;
  bool get meshParticipation => _meshParticipation;
  bool get autoSOS => _autoSOS;
  bool get continuousBroadcast => _continuousBroadcast;
  int get sosIntervalSeconds => _sosIntervalSeconds;
  bool get encryptionEnabled => _encryptionEnabled;
  String get visibilityMode => _visibilityMode;
  bool get powerSaveMode => _powerSaveMode;
  int get scanIntervalSeconds => _scanIntervalSeconds;
  int get maxHops => _maxHops;
  int get retryAttempts => _retryAttempts;
  int get messageTTL => _messageTTL;
  String get mapRegion => _mapRegion;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _bluetoothEnabled = prefs.getBool('setting_bluetooth') ?? true;
    _autoDiscovery = prefs.getBool('setting_autoDiscovery') ?? false;
    _meshParticipation = prefs.getBool('setting_meshParticipation') ?? true;
    _autoSOS = prefs.getBool('setting_autoSOS') ?? false;
    _continuousBroadcast = prefs.getBool('setting_continuousBroadcast') ?? false;
    _sosIntervalSeconds = prefs.getInt('setting_sosInterval') ?? 15;
    _encryptionEnabled = prefs.getBool('setting_encryption') ?? true;
    _visibilityMode = prefs.getString('setting_visibility') ?? 'limited';
    _powerSaveMode = prefs.getBool('setting_powerSave') ?? true;
    _scanIntervalSeconds = prefs.getInt('setting_scanInterval') ?? 10;
    _maxHops = prefs.getInt('setting_maxHops') ?? 20;
    _retryAttempts = prefs.getInt('setting_retryAttempts') ?? 3;
    _messageTTL = prefs.getInt('setting_messageTTL') ?? 30;
    _mapRegion = prefs.getString('setting_mapRegion') ?? 'Auto';
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_$key', value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('setting_$key', value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_$key', value);
  }

  Future<void> setBluetoothEnabled(bool v) async {
    _bluetoothEnabled = v;
    notifyListeners();
    await _saveBool('bluetooth', v);
  }

  Future<void> setAutoDiscovery(bool v) async {
    _autoDiscovery = v;
    notifyListeners();
    await _saveBool('autoDiscovery', v);
  }

  Future<void> setMeshParticipation(bool v) async {
    _meshParticipation = v;
    notifyListeners();
    await _saveBool('meshParticipation', v);
  }

  Future<void> setAutoSOS(bool v) async {
    _autoSOS = v;
    notifyListeners();
    await _saveBool('autoSOS', v);
  }

  Future<void> setContinuousBroadcast(bool v) async {
    _continuousBroadcast = v;
    notifyListeners();
    await _saveBool('continuousBroadcast', v);
  }

  Future<void> setSosInterval(int v) async {
    _sosIntervalSeconds = v;
    notifyListeners();
    await _saveInt('sosInterval', v);
  }

  Future<void> setEncryptionEnabled(bool v) async {
    _encryptionEnabled = v;
    notifyListeners();
    await _saveBool('encryption', v);
  }

  Future<void> setVisibilityMode(String v) async {
    _visibilityMode = v;
    notifyListeners();
    await _saveString('visibility', v);
  }

  Future<void> setPowerSaveMode(bool v) async {
    _powerSaveMode = v;
    notifyListeners();
    await _saveBool('powerSave', v);
  }

  Future<void> setScanInterval(int v) async {
    _scanIntervalSeconds = v;
    notifyListeners();
    await _saveInt('scanInterval', v);
  }

  Future<void> setMaxHops(int v) async {
    _maxHops = v;
    notifyListeners();
    await _saveInt('maxHops', v);
  }

  Future<void> setRetryAttempts(int v) async {
    _retryAttempts = v;
    notifyListeners();
    await _saveInt('retryAttempts', v);
  }

  Future<void> setMapRegion(String v) async {
    _mapRegion = v;
    notifyListeners();
    await _saveString('mapRegion', v);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('setting_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    await _loadSettings();
  }
}
