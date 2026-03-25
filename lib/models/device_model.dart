class DeviceInfo {
  final String id;
  final String name;
  final int rssi;
  final double estimatedDistance;
  final int hopCount;
  final String status;
  final DateTime lastSeen;
  final bool isDirect;
  final String deviceType;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    this.estimatedDistance = 0.0,
    this.hopCount = 0,
    this.status = 'Active',
    DateTime? lastSeen,
    this.isDirect = true,
    this.deviceType = 'smartphone',
  }) : lastSeen = lastSeen ?? DateTime.now();

  String get distanceLabel {
    if (estimatedDistance < 1000) {
      return '~${estimatedDistance.toStringAsFixed(0)}m';
    }
    return '~${(estimatedDistance / 1000).toStringAsFixed(1)}km';
  }

  String get hopLabel {
    if (hopCount == 0) return 'DIRECT';
    return '$hopCount ${hopCount == 1 ? "HOP" : "HOPS"}';
  }

  String get lastActiveLabel {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) return 'Active now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    return 'Active ${diff.inHours}h ago';
  }

  /// Estimate distance from RSSI (approximate formula)
  static double estimateDistanceFromRssi(int rssi, {double txPower = -59}) {
    if (rssi == 0) return -1.0;
    final ratio = rssi / txPower;
    if (ratio < 1.0) {
      return ratio * ratio * ratio * 10;
    }
    return (0.89976) * (ratio * ratio * ratio) + 0.111;
  }

  DeviceInfo copyWith({
    String? id,
    String? name,
    int? rssi,
    double? estimatedDistance,
    int? hopCount,
    String? status,
    DateTime? lastSeen,
    bool? isDirect,
    String? deviceType,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      hopCount: hopCount ?? this.hopCount,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isDirect: isDirect ?? this.isDirect,
      deviceType: deviceType ?? this.deviceType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rssi': rssi,
      'estimatedDistance': estimatedDistance,
      'hopCount': hopCount,
      'status': status,
      'lastSeen': lastSeen.toIso8601String(),
      'isDirect': isDirect ? 1 : 0,
      'deviceType': deviceType,
    };
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      id: map['id'] as String,
      name: map['name'] as String,
      rssi: map['rssi'] as int,
      estimatedDistance: (map['estimatedDistance'] as num).toDouble(),
      hopCount: map['hopCount'] as int,
      status: map['status'] as String,
      lastSeen: DateTime.parse(map['lastSeen'] as String),
      isDirect: map['isDirect'] == 1,
      deviceType: map['deviceType'] as String,
    );
  }
}
