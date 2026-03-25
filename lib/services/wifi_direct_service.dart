import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import '../models/message_model.dart';
import 'profile_service.dart';
import 'settings_service.dart';

/// Wi-Fi Direct P2P service for high-speed, router-free communication.
/// Each device can be a Host (group owner) or Client (joiner).
class WiFiDirectService extends ChangeNotifier {
  final ProfileService _profileService;
  final SettingsService _settingsService;

  FlutterP2pHost? _host;
  FlutterP2pClient? _client;

  bool _isHosting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  bool _wifiDirectEnabled = false;
  final List<String> _connectedPeers = [];
  final List<BleDiscoveredDevice> _discoveredHosts = [];

  // Streams
  StreamSubscription? _hostTextSubscription;
  StreamSubscription? _clientTextSubscription;
  StreamSubscription? _clientListSubscription;

  // Callbacks for incoming messages
  Function(ChatMessage)? onMessageReceived;

  // Getters
  bool get isHosting => _isHosting;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  bool get wifiDirectEnabled => _wifiDirectEnabled;
  List<String> get connectedPeers => List.unmodifiable(_connectedPeers);
  List<BleDiscoveredDevice> get discoveredHosts =>
      List.unmodifiable(_discoveredHosts);
  int get peerCount => _connectedPeers.length;

  WiFiDirectService({
    required ProfileService profileService,
    required SettingsService settingsService,
  })  : _profileService = profileService,
        _settingsService = settingsService;

  /// Initialize permissions and services
  Future<bool> initialize() async {
    try {
      _host = FlutterP2pHost();
      _client = FlutterP2pClient();

      await _host!.initialize();
      await _client!.initialize();

      // Check and request permissions
      if (!await _host!.checkP2pPermissions()) {
        await _host!.askP2pPermissions();
      }

      return true;
    } catch (e) {
      debugPrint('WiFi Direct init error: $e');
      return false;
    }
  }

  /// Enable/disable Wi-Fi Direct
  Future<void> setWifiDirectEnabled(bool enabled) async {
    _wifiDirectEnabled = enabled;
    if (enabled) {
      final success = await initialize();
      if (success) {
        // Start as host by default to be discoverable
        await startHosting();
      }
    } else {
      await stopAll();
    }
    notifyListeners();
  }

  /// Start as a Wi-Fi Direct Group Owner (Host)
  Future<void> startHosting() async {
    if (_isHosting || _host == null) return;

    try {
      // Enable Wi-Fi if needed
      if (!await _host!.checkWifiEnabled()) {
        await _host!.enableWifiServices();
      }

      await _host!.createGroup(advertise: true);
      _isHosting = true;

      // Listen for incoming text messages via streamReceivedTexts()
      _hostTextSubscription?.cancel();
      _hostTextSubscription =
          _host!.streamReceivedTexts().listen((message) {
        _handleIncomingText(message);
      });

      // Listen for client list changes
      _clientListSubscription?.cancel();
      _clientListSubscription =
          _host!.streamClientList().listen((clients) {
        _connectedPeers.clear();
        for (final client in clients) {
          _connectedPeers.add(client.username);
        }
        notifyListeners();
      });

      debugPrint('WiFi Direct: Hosting as "${_profileService.profile.name}"');
      notifyListeners();
    } catch (e) {
      debugPrint('WiFi Direct host error: $e');
    }
  }

  /// Stop hosting
  Future<void> stopHosting() async {
    if (!_isHosting || _host == null) return;

    try {
      _hostTextSubscription?.cancel();
      _clientListSubscription?.cancel();
      await _host!.removeGroup();
      _isHosting = false;
      _connectedPeers.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('WiFi Direct stop host error: $e');
    }
  }

  /// Discover nearby Wi-Fi Direct hosts via BLE
  Future<void> startDiscovery() async {
    if (_isScanning || _client == null) return;

    try {
      _isScanning = true;
      _discoveredHosts.clear();
      notifyListeners();

      await _client!.startScan((devices) {
        _discoveredHosts.clear();
        _discoveredHosts.addAll(devices);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('WiFi Direct discovery error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop discovery
  Future<void> stopDiscovery() async {
    if (!_isScanning || _client == null) return;

    try {
      await _client!.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('WiFi Direct stop discovery error: $e');
    }
  }

  /// Connect to a discovered host
  Future<bool> connectToHost(BleDiscoveredDevice device) async {
    if (_client == null) return false;

    try {
      await _client!.connectWithDevice(device);
      _isConnected = true;

      // Listen for incoming text messages from host
      _clientTextSubscription?.cancel();
      _clientTextSubscription =
          _client!.streamReceivedTexts().listen((message) {
        _handleIncomingText(message);
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('WiFi Direct connect error: $e');
      return false;
    }
  }

  /// Broadcast a text message over Wi-Fi Direct
  Future<bool> broadcastText(String text) async {
    try {
      if (_isHosting && _host != null) {
        await _host!.broadcastText(text);
        return true;
      } else if (_isConnected && _client != null) {
        await _client!.broadcastText(text);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('WiFi Direct broadcast error: $e');
      return false;
    }
  }

  /// Send a ChatMessage over Wi-Fi Direct
  Future<bool> sendMessage(ChatMessage message) async {
    final payload = jsonEncode(message.toMap());
    return broadcastText(payload);
  }

  /// Handle incoming text — try to parse as ChatMessage
  void _handleIncomingText(String text) {
    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      final message = ChatMessage.fromMap(map);
      onMessageReceived?.call(message);
    } catch (e) {
      // Not a ChatMessage, treat as plain text
      debugPrint('WiFi Direct received plain text: $text');
    }
  }

  /// Disconnect from a host (client mode)
  Future<void> disconnect() async {
    if (_client == null) return;
    try {
      _clientTextSubscription?.cancel();
      await _client!.disconnect();
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      debugPrint('WiFi Direct disconnect error: $e');
    }
  }

  /// Stop all Wi-Fi Direct activity
  Future<void> stopAll() async {
    await stopHosting();
    await stopDiscovery();
    await disconnect();
    _wifiDirectEnabled = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _hostTextSubscription?.cancel();
    _clientTextSubscription?.cancel();
    _clientListSubscription?.cancel();
    _host?.dispose();
    _client?.dispose();
    super.dispose();
  }
}
