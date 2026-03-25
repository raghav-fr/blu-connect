class SOSSignal {
  final String id;
  final String senderName;
  final String senderId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String bloodGroup;
  final String medicalNote;
  final bool isContinuous;

  SOSSignal({
    required this.id,
    required this.senderName,
    required this.senderId,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
    this.bloodGroup = '',
    this.medicalNote = '',
    this.isContinuous = false,
  }) : timestamp = timestamp ?? DateTime.now();

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(4)}° ${latitude >= 0 ? "N" : "S"}\n${longitude.abs().toStringAsFixed(4)}° ${longitude >= 0 ? "E" : "W"}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderName': senderName,
      'senderId': senderId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'bloodGroup': bloodGroup,
      'medicalNote': medicalNote,
      'isContinuous': isContinuous ? 1 : 0,
    };
  }

  factory SOSSignal.fromMap(Map<String, dynamic> map) {
    return SOSSignal(
      id: map['id'] as String,
      senderName: map['senderName'] as String,
      senderId: map['senderId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      bloodGroup: map['bloodGroup'] as String? ?? '',
      medicalNote: map['medicalNote'] as String? ?? '',
      isContinuous: map['isContinuous'] == 1,
    );
  }
}
