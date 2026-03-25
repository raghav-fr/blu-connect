import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/message_model.dart';
import 'bluetooth_service.dart';
import 'wifi_direct_service.dart';
import 'message_service.dart';

/// Mesh networking layer that handles multi-hop message relay over BLE + Wi-Fi Direct.
class MeshService extends ChangeNotifier {
  final BluetoothService _bleService;
  final MessageService _messageService;
  WiFiDirectService? _wifiService;
  
  final Set<String> _processedMessageIds = {};
  final List<String> _routingLog = [];
  int _maxHops = 20;
  int _retryAttempts = 3;
  bool _relayEnabled = true;
  DateTime? _lastSyncTime;

  List<String> get routingLog => List.unmodifiable(_routingLog);
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get relayEnabled => _relayEnabled;
  int get maxHops => _maxHops;
  bool get hasWifiDirect =>
      _wifiService != null && _wifiService!.wifiDirectEnabled;

  String get lastSyncLabel {
    if (_lastSyncTime == null) return 'Never';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String get transportMode {
    if (hasWifiDirect && _bleService.meshEnabled) return 'BLE + Wi-Fi Direct';
    if (hasWifiDirect) return 'Wi-Fi Direct';
    if (_bleService.meshEnabled) return 'BLE';
    return 'Offline';
  }

  MeshService({
    required BluetoothService bleService,
    required MessageService messageService,
    WiFiDirectService? wifiService,
  })  : _bleService = bleService,
        _messageService = messageService,
        _wifiService = wifiService {
    _init();
  }

  void _init() {
    // Listen for incoming BLE data from the GATT Server
    _bleService.onDataReceived = (data) {
      _handleRawData(data);
    };
  }

  void updateWifiService(WiFiDirectService? wifiService) {
    _wifiService = wifiService;
    // Also wire up WiFi Direct reception if not already done
    if (_wifiService != null) {
      _wifiService!.onMessageReceived = (message) {
        handleIncomingMessage(message);
      };
    }
    notifyListeners();
  }

  void _handleRawData(List<int> data) {
    try {
      final payload = utf8.decode(data);
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final message = ChatMessage.fromMap(map);
      handleIncomingMessage(message);
    } catch (e) {
      debugPrint('Mesh: Failed to parse raw data: $e');
    }
  }

  void setMaxHops(int hops) {
    _maxHops = hops;
    notifyListeners();
  }

  void setRelayEnabled(bool enabled) {
    _relayEnabled = enabled;
    notifyListeners();
  }

  /// Broadcast a message to all nearby devices via ALL available transports
  Future<bool> broadcastMessage(ChatMessage message) async {
    // Dedup
    if (_processedMessageIds.contains(message.id) && message.status != MessageStatus.sent) {
      return false;
    }
    _processedMessageIds.add(message.id);

    final payload = jsonEncode(message.toMap());
    final data = utf8.encode(payload);

    bool sent = false;

    // 1. Try Wi-Fi Direct first (faster, longer range)
    if (hasWifiDirect) {
      try {
        final wifiSent = await _wifiService!.sendMessage(message);
        if (wifiSent) {
          sent = true;
          _routingLog.add('[${DateTime.now().toIso8601String()}] WiFi-Direct broadcast ✓');
        }
      } catch (e) {
        _routingLog.add('[${DateTime.now().toIso8601String()}] WiFi-Direct failed: $e');
      }
    }

    // 2. Also send via BLE to all discovered devices
    for (final device in _bleService.discoveredDevices) {
      try {
        await _bleService.sendData(device.id, data);
        sent = true;
        _routingLog.add('[${DateTime.now().toIso8601String()}] BLE → ${device.name}');
      } catch (e) {
        // Ignore individual failures, keep trying others
      }
    }

    _lastSyncTime = DateTime.now();
    notifyListeners();
    return sent;
  }

  /// Handle an incoming message — deliver to UI and relay if needed
  Future<void> handleIncomingMessage(ChatMessage message) async {
    // Loop prevention
    if (_processedMessageIds.contains(message.id)) return;
    _processedMessageIds.add(message.id);

    _routingLog.add('[${DateTime.now().toIso8601String()}] Received: ${message.content.substring(0, min(message.content.length, 10))}...');

    // 1. Deliver to local MessageService (UI)
    await _messageService.receiveMessage(message.copyWith(
      hopCount: message.hopCount + 1,
      status: MessageStatus.delivered,
    ));

    // 2. Relay to others if TTL > 0
    if (_relayEnabled && message.ttl > 0 && message.hopCount < _maxHops) {
      final relayed = message.copyWith(
        ttl: message.ttl - 1,
        hopCount: message.hopCount + 1,
        status: MessageStatus.relayed,
      );
      
      // Give a small delay to avoid collision if multiple nodes receive simultaneously
      await Future.delayed(const Duration(milliseconds: 200));
      await broadcastMessage(relayed);
    }

    _lastSyncTime = DateTime.now();
    notifyListeners();
  }

  int min(int a, int b) => a < b ? a : b;

  void clearProcessedIds() {
    _processedMessageIds.clear();
    notifyListeners();
  }
}
