import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import 'location_service.dart';
import 'message_service.dart';
import 'profile_service.dart';
import 'settings_service.dart';

class EmergencyService extends ChangeNotifier {
  final SettingsService _settings;
  final LocationService _location;
  final MessageService _messageService;
  final ProfileService _profile;

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  Timer? _sosCountdownTimer;
  int _countdownSeconds = 0;
  bool _isSosTriggered = false;

  bool get isSosTriggered => _isSosTriggered;
  int get countdownSeconds => _countdownSeconds;

  EmergencyService({
    required SettingsService settings,
    required LocationService location,
    required MessageService messageService,
    required ProfileService profile,
  })  : _settings = settings,
        _location = location,
        _messageService = messageService,
        _profile = profile {
    _init();
  }

  void _init() {
    _settings.addListener(_onSettingsChanged);
    // Initial check
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    if (_settings.autoSOS) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }
  }

  void _startMonitoring() {
    if (_accelerometerSubscription != null) return;
    
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      // Calculate total G-force change (excluding static gravity)
      // A sudden spike typically indicates a fall or impact.
      final totalForce = (event.x.abs() + event.y.abs() + event.z.abs());
      
      // 35.0 m/s^2 is ~3.5G, a significant impact for a handheld device.
      if (totalForce > 35.0 && !_isSosTriggered) {
        _triggerAutoSos();
      }
    });
  }

  void _stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void _triggerAutoSos() {
    _isSosTriggered = true;
    _countdownSeconds = 10;
    notifyListeners();

    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        // Pulse vibration to warn the user
        _pulseVibration();
        notifyListeners();
      } else {
        _performSosBroadcast();
        timer.cancel();
      }
    });
  }

  Future<void> _pulseVibration() async {
    final canVibrate = await Vibrate.canVibrate;
    if (canVibrate) {
      Vibrate.feedback(FeedbackType.medium);
    }
  }

  void cancelSos() {
    _sosCountdownTimer?.cancel();
    _isSosTriggered = false;
    _countdownSeconds = 0;
    notifyListeners();
  }

  Future<void> _performSosBroadcast() async {
    _isSosTriggered = false;
    notifyListeners();

    final position = _location.currentPosition;
    final message = ChatMessage(
      id: const Uuid().v4(),
      senderId: _profile.profile.id,
      senderName: _profile.profile.name,
      content: "AUTOMATIC SOS: Impact detected. User may be incapacitated.",
      timestamp: DateTime.now(),
      type: MessageType.sos,
      latitude: position?.latitude,
      longitude: position?.longitude,
      isBroadcast: true,
    );

    try {
      await _messageService.receiveMessage(message); 
      // In this app, sendMessage is usually handled by the MeshService or similar.
      // But MessageService's sendCommunityMessage is the best entry point for local UI + DB.
      await _messageService.sendCommunityMessage(
        senderId: _profile.profile.id,
        senderName: _profile.profile.name,
        content: message.content,
        type: MessageType.sos,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      final canVibrate = await Vibrate.canVibrate;
      if (canVibrate) {
        Vibrate.feedback(FeedbackType.heavy);
      }
    } catch (e) {
      debugPrint('Auto SOS broadcast error: $e');
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _stopMonitoring();
    _sosCountdownTimer?.cancel();
    super.dispose();
  }
}
