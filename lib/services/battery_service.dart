import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';

class BatteryService extends ChangeNotifier {
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _stateSubscription;
  Timer? _levelTimer;

  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  bool get isCharging => _batteryState == BatteryState.charging;
  bool get isLowBattery => _batteryLevel <= 20;

  String get batteryLabel => '$_batteryLevel% Power';

  BatteryService() {
    _init();
  }

  Future<void> _init() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      notifyListeners();
    } catch (_) {}

    _stateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      notifyListeners();
    });

    // Refresh battery level every 30s
    _levelTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        _batteryLevel = await _battery.batteryLevel;
        notifyListeners();
      } catch (_) {}
    });
  }

  Future<void> refreshBatteryLevel() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }
}
