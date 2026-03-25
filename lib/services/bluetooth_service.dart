import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device_model.dart';
import 'profile_service.dart';
import 'settings_service.dart';

/// Unique Service UUID for Blu Connect mesh discovery and data exchange.
const String _meshServiceUuid = '4a9b5f1e-3c2d-4e5f-a1b2-c3d4e5f6a7b8';
const String _meshCharacteristicUuid = 'b8a7f6e5-d4c3-b2a1-5e4f-3c2d1e5b9a4a';

/// Names that indicate audio/wearable peripherals we want to filter OUT.
const _excludedNamePatterns = [
  'airpod', 'buds', 'earbuds', 'earbud',
  'headphone', 'headset', 'earphone',
  'speaker', 'soundbar', 'soundcore', 'jbl',
  'bose', 'sony wf', 'sony wh', 'beats',
  'galaxy buds', 'pixel buds', 'nothing ear',
  'airdopes', 'boat', 'noise',
  'band', 'watch', 'fitbit', 'mi band', 'amazfit',
  'smartwatch', 'garmin', 'huawei watch',
  'mouse', 'keyboard', 'remote', 'controller',
  'gamepad', 'joystick',
  'tv', 'chromecast', 'fire stick', 'roku',
  'printer', 'scale', 'toothbrush', 'tile', 'tag',
  'airtag', 'smarttag',
];

/// Names that indicate this IS a phone/tablet (should be included).
const _phoneNamePatterns = [
  'phone', 'pixel', 'samsung', 'galaxy', 'oneplus',
  'xiaomi', 'redmi', 'poco', 'realme', 'oppo', 'vivo',
  'motorola', 'moto', 'nokia', 'lg', 'huawei', 'honor',
  'iphone', 'ipad', 'tablet', 'blu connect',
  'nothing phone', 'asus', 'rog phone', 'sony xperia',
];

/// Standard BLE service UUIDs for audio devices (to filter them out).
const _audioServiceUuids = [
  '0000110a', // Audio Source
  '0000110b', // Audio Sink
  '0000110c', // A/V Remote Control Target
  '0000110d', // Advanced Audio Distribution
  '0000110e', // A/V Remote Control
  '00001108', // Headset
  '0000111e', // Handsfree
  '00001112', // Headset AG
  '00001131', // Headset HS
  '00001203', // Generic Audio
  '0000184e', // Audio Stream Control
];

class BluetoothService extends ChangeNotifier {
  final ProfileService _profileService;
  final SettingsService _settingsService;
  
  final List<DeviceInfo> _discoveredDevices = [];
  final List<DeviceInfo> _allRawDevices = [];
  
  bool _isScanning = false;
  bool _isAdvertising = false;
  bool _isBluetoothOn = false;
  bool _autoDiscovery = false;
  bool _showAllDevices = false;
  bool _meshEnabled = true;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  Timer? _autoScanTimer;

  // Callback for incoming data via GATT Server
  Function(List<int>)? onDataReceived;

  List<DeviceInfo> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<DeviceInfo> get allRawDevices => List.unmodifiable(_allRawDevices);
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  bool get isBluetoothOn => _isBluetoothOn;
  bool get autoDiscovery => _autoDiscovery;
  bool get showAllDevices => _showAllDevices;
  bool get meshEnabled => _meshEnabled;
  int get connectedDeviceCount => _discoveredDevices.length;

  BluetoothService({
    required ProfileService profileService,
    required SettingsService settingsService,
  })  : _profileService = profileService,
        _settingsService = settingsService {
    _init();
  }

  Future<void> _init() async {
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      _isBluetoothOn = state == BluetoothAdapterState.on;
      notifyListeners();
      
      if (_isBluetoothOn) {
        if (_autoDiscovery) startScan();
        if (_meshEnabled) _startGattServer();
      } else {
        _stopGattServer();
        _isScanning = false;
      }
    });

    try {
      final state = await FlutterBluePlus.adapterState.first;
      _isBluetoothOn = state == BluetoothAdapterState.on;
      notifyListeners();
    } catch (_) {}

    _settingsService.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (_isBluetoothOn && _settingsService.continuousBroadcast && _meshEnabled) {
      _startGattServer();
    }
  }

  Future<bool> requestPermissions() async {
    final List<Permission> permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ];

    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  void toggleShowAllDevices() {
    _showAllDevices = !_showAllDevices;
    _applyFilter();
    notifyListeners();
  }

  void setMeshEnabled(bool enabled) {
    _meshEnabled = enabled;
    if (enabled) {
      if (_isBluetoothOn) _startGattServer();
      if (_autoDiscovery) startScan();
    } else {
      _stopGattServer();
      stopScan();
    }
    notifyListeners();
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 12)}) async {
    if (_isScanning || !_isBluetoothOn) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _isScanning = true;
    notifyListeners();

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (result.advertisementData.advName.isEmpty && result.rssi < -85) {
          continue;
        }

        String name = result.advertisementData.advName;
        if (name.isEmpty) {
          name = 'Unknown (${result.device.remoteId.str.substring(0, 8)})';
        }

        // Strip the "Blu: " prefix if present for a cleaner UI
        if (name.startsWith('Blu: ')) {
          name = name.substring(5);
        }

        final deviceType = _classifyDevice(result);
        final isExcluded = _shouldExcludeDevice(result, deviceType);

        final device = DeviceInfo(
          id: result.device.remoteId.str,
          name: name,
          rssi: result.rssi,
          estimatedDistance: DeviceInfo.estimateDistanceFromRssi(result.rssi),
          hopCount: 0,
          status: 'Active',
          lastSeen: DateTime.now(),
          isDirect: true,
          deviceType: deviceType,
        );

        final rawIndex = _allRawDevices.indexWhere((d) => d.id == device.id);
        if (rawIndex >= 0) {
          _allRawDevices[rawIndex] = device;
        } else {
          _allRawDevices.add(device);
        }

        if (!isExcluded || _showAllDevices) {
          final existingIndex = _discoveredDevices.indexWhere((d) => d.id == device.id);
          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = device;
          } else {
            _discoveredDevices.add(device);
          }
        }
      }
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        removeIfGone: const Duration(seconds: 30),
        continuousUpdates: true,
      );
    } catch (e) {
      debugPrint('BLE scan error: $e');
    }

    _isScanning = false;
    notifyListeners();
  }

  /// Start acting as a Peripheral with a GATT Server
  Future<void> _startGattServer() async {
    if (_isAdvertising || !_isBluetoothOn || !_meshEnabled) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      // 1. Initialise the peripheral
      await BlePeripheral.initialize();
      
      // 2. Add the mesh service and characteristic with FIXED TYPES for v2.4.0
      await BlePeripheral.addService(
        BleService(
          uuid: _meshServiceUuid,
          primary: true,
          characteristics: [
            BleCharacteristic(
              uuid: _meshCharacteristicUuid,
              properties: [
                CharacteristicProperty.write,
                CharacteristicProperty.writeWithoutResponse,
                CharacteristicProperty.notify,
              ],
              permissions: [
                AttributePermission.writeable,
              ],
            ),
          ],
        ),
      );

      // 3. Set up the write callback with FIXED SIGNATURE for v2.4.0
      BlePeripheral.setWriteRequestCallback((BleDevice device, String characteristicUuid, Uint8List? value) {
        if (characteristicUuid == _meshCharacteristicUuid && value != null) {
          debugPrint('GATT: Received data from ${device.address}');
          onDataReceived?.call(value.toList());
        }
      });

      // 4. Start advertising
      final name = _profileService.profile.name.isNotEmpty 
          ? _profileService.profile.name 
          : 'Blu User';
          
      await BlePeripheral.startAdvertising(
        services: [_meshServiceUuid],
        localName: 'Blu: $name',
      );

      _isAdvertising = true;
      notifyListeners();
    } catch (e) {
      debugPrint('BLE GATT Server error: $e');
    }
  }

  Future<void> _stopGattServer() async {
    try {
      await BlePeripheral.stopAdvertising();
      _isAdvertising = false;
      notifyListeners();
    } catch (e) {
      debugPrint('BLE Stop GATT Server error: $e');
    }
  }

  /// Connect to a device and send raw data (Message relaying)
  Future<void> sendData(String deviceId, List<int> data) async {
    if (!_isBluetoothOn) return;
    
    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(timeout: const Duration(seconds: 5));
      
      try {
        final services = await device.discoverServices();
        bool characteristicFound = false;
        
        for (final service in services) {
          if (service.uuid.toString().toLowerCase() != _meshServiceUuid.toLowerCase()) continue;
          
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == _meshCharacteristicUuid.toLowerCase()) {
              await characteristic.write(data, withoutResponse: characteristic.properties.writeWithoutResponse);
              characteristicFound = true;
              break;
            }
          }
          if (characteristicFound) break;
        }
        
        if (!characteristicFound) {
          throw Exception('No Blu Mesh characteristic found on device $deviceId');
        }
      } finally {
        await device.disconnect();
      }
    } catch (e) {
      debugPrint('Send data error to $deviceId: $e');
      rethrow;
    }
  }

  void _applyFilter() {
    _discoveredDevices.clear();
    for (final device in _allRawDevices) {
      if (_showAllDevices || !_isExcludedDeviceType(device.deviceType)) {
        _discoveredDevices.add(device);
      }
    }
  }

  bool _isExcludedDeviceType(String type) {
    return type == 'headset' ||
        type == 'speaker' ||
        type == 'wearable' ||
        type == 'peripheral' ||
        type == 'unknown';
  }

  String _classifyDevice(ScanResult result) {
    final advName = result.advertisementData.advName.toLowerCase();
    final serviceUuids = result.advertisementData.serviceUuids
        .map((u) => u.toString().toLowerCase())
        .toList();

    if (serviceUuids.contains(_meshServiceUuid.toLowerCase())) {
      return 'smartphone';
    }

    if (advName.contains('blu connect') || advName.contains('blu:')) {
      return 'smartphone';
    }

    for (final pattern in _excludedNamePatterns) {
      if (advName.contains(pattern)) {
        if (['airpod', 'buds', 'earbuds', 'earbud', 'headphone', 'headset',
             'earphone', 'airdopes', 'boat', 'noise', 'sony wf', 'sony wh',
             'beats', 'bose', 'galaxy buds', 'pixel buds', 'nothing ear']
            .any((a) => advName.contains(a))) {
          return 'headset';
        }
        if (['speaker', 'soundbar', 'soundcore', 'jbl'].any((a) => advName.contains(a))) {
          return 'speaker';
        }
        if (['band', 'watch', 'fitbit', 'mi band', 'amazfit', 'smartwatch'].any((a) => advName.contains(a))) {
          return 'wearable';
        }
        return 'peripheral';
      }
    }

    for (final pattern in _phoneNamePatterns) {
      if (advName.contains(pattern)) return 'smartphone';
    }

    for (final uuid in serviceUuids) {
      for (final audioUuid in _audioServiceUuids) {
        if (uuid.contains(audioUuid)) return 'headset';
      }
    }

    if (advName.contains('drone') || advName.contains('pi') || advName.contains('raspberry')) return 'drone';
    if (advName.contains('repeater') || advName.contains('router')) return 'router';

    if (result.advertisementData.advName.isNotEmpty && result.advertisementData.connectable) {
      return 'smartphone';
    }

    return 'unknown';
  }

  bool _shouldExcludeDevice(ScanResult result, String deviceType) {
    if (deviceType == 'headset' || deviceType == 'speaker' ||
        deviceType == 'wearable' || deviceType == 'peripheral') {
      return true;
    }
    if (result.advertisementData.advName.isEmpty && result.rssi < -80) return true;
    if (deviceType == 'unknown') return true;
    return false;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  void setAutoDiscovery(bool enabled) {
    _autoDiscovery = enabled;
    if (enabled) {
      _autoScanTimer?.cancel();
      _autoScanTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_isBluetoothOn && !_isScanning) startScan();
      });
      if (_isBluetoothOn && _meshEnabled) startScan();
    } else {
      _autoScanTimer?.cancel();
      _autoScanTimer = null;
    }
    notifyListeners();
  }

  void clearAndRescan() {
    _discoveredDevices.clear();
    _allRawDevices.clear();
    notifyListeners();
    startScan();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    _autoScanTimer?.cancel();
    FlutterBluePlus.stopScan();
    _stopGattServer();
    super.dispose();
  }
}
