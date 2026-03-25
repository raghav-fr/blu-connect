import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  String? _error;
  bool _isAcquiring = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get hasPosition => _currentPosition != null;
  String? get error => _error;
  bool get isAcquiring => _isAcquiring;

  double get latitude => _currentPosition?.latitude ?? 0.0;
  double get longitude => _currentPosition?.longitude ?? 0.0;

  String get coordinatesLabel {
    if (_currentPosition == null) {
      if (_error != null) return _error!;
      return 'Acquiring GPS...';
    }
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    return '${lat.abs().toStringAsFixed(4)}° ${lat >= 0 ? "N" : "S"}\n${lng.abs().toStringAsFixed(4)}° ${lng >= 0 ? "E" : "W"}';
  }

  LocationService() {
    // Immediately try to get position on creation
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Try last known position first (instant, no GPS needed)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentPosition = lastKnown;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Last known position error: $e');
    }

    // Then get a fresh position
    await getCurrentPosition();
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Turn on Location in device settings';
      notifyListeners();

      // Try to open location settings
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permission denied';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'Enable location in App Settings';
      notifyListeners();
      await Geolocator.openAppSettings();
      return false;
    }

    _error = null;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return _currentPosition;

    _isAcquiring = true;
    notifyListeners();

    // Step 1: Get last known position instantly (cached by the OS)
    if (_currentPosition == null) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _currentPosition = lastKnown;
          _error = null;
          notifyListeners();
        }
      } catch (_) {}
    }

    // Step 2: Get a fresh high-accuracy position (may take time on cold GPS start)
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: false,
          // No timeLimit here — let the GPS take its time to lock
        ),
      );
      _error = null;
    } catch (e) {
      debugPrint('GPS getCurrentPosition error: $e');
      // If high accuracy fails, try lower accuracy as fallback
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.medium,
            forceLocationManager: true,
          ),
        );
        _error = null;
      } catch (e2) {
        debugPrint('GPS fallback error: $e2');
        if (_currentPosition == null) {
          _error = 'GPS signal weak. Move outdoors.';
        }
      }
    }

    _isAcquiring = false;
    notifyListeners();
    return _currentPosition;
  }

  Future<void> startContinuousTracking({
    Duration interval = const Duration(seconds: 5),
  }) async {
    if (_isTracking) return;

    final hasPermission = await _checkPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    notifyListeners();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: interval,
        forceLocationManager: false,
      ),
    ).listen(
      (position) {
        _currentPosition = position;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Continuous tracking error: $e');
        _error = 'GPS tracking error';
        notifyListeners();
      },
    );
  }

  void stopContinuousTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
