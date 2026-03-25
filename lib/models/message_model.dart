enum MessageType { info, alert, sos }

enum MessageStatus { sending, sent, relayed, delivered, failed }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final int hopCount;
  final MessageStatus status;
  final List<String> routingPath;
  final bool isBroadcast;
  final bool isMine;
  final double? latitude;
  final double? longitude;
  final int ttl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    DateTime? timestamp,
    this.type = MessageType.info,
    this.hopCount = 0,
    this.status = MessageStatus.sending,
    this.routingPath = const [],
    this.isBroadcast = false,
    this.isMine = false,
    this.latitude,
    this.longitude,
    this.ttl = 20,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasLocation => latitude != null && longitude != null;

  String get typeLabel {
    switch (type) {
      case MessageType.sos:
        return 'SOS';
      case MessageType.alert:
        return 'ALERT';
      case MessageType.info:
        return 'INFO';
    }
  }

  String get statusLabel {
    switch (status) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.relayed:
        return 'Relayed';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    int? hopCount,
    MessageStatus? status,
    List<String>? routingPath,
    bool? isBroadcast,
    bool? isMine,
    double? latitude,
    double? longitude,
    int? ttl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      hopCount: hopCount ?? this.hopCount,
      status: status ?? this.status,
      routingPath: routingPath ?? this.routingPath,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      isMine: isMine ?? this.isMine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ttl: ttl ?? this.ttl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'hopCount': hopCount,
      'status': status.index,
      'routingPath': routingPath.join(','),
      'isBroadcast': isBroadcast ? 1 : 0,
      'isMine': isMine ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'ttl': ttl,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: MessageType.values[map['type'] as int],
      hopCount: map['hopCount'] as int,
      status: MessageStatus.values[map['status'] as int],
      routingPath: (map['routingPath'] as String).isEmpty
          ? []
          : (map['routingPath'] as String).split(','),
      isBroadcast: map['isBroadcast'] == 1,
      isMine: map['isMine'] == 1,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      ttl: map['ttl'] as int,
    );
  }
}
