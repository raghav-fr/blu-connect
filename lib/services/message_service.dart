import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

class MessageService extends ChangeNotifier {
  Database? _db;
  final List<ChatMessage> _communityMessages = [];
  final Map<String, List<ChatMessage>> _privateMessages = {};
  final _uuid = const Uuid();

  List<ChatMessage> get communityMessages => List.unmodifiable(_communityMessages);

  List<ChatMessage> getPrivateMessages(String deviceId) {
    return List.unmodifiable(_privateMessages[deviceId] ?? []);
  }

  MessageService() {
    _initDb();
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'bluconnect_messages.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            senderId TEXT NOT NULL,
            senderName TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            type INTEGER NOT NULL,
            hopCount INTEGER DEFAULT 0,
            status INTEGER DEFAULT 0,
            routingPath TEXT DEFAULT '',
            isBroadcast INTEGER DEFAULT 0,
            isMine INTEGER DEFAULT 0,
            latitude REAL,
            longitude REAL,
            ttl INTEGER DEFAULT 20,
            targetDeviceId TEXT
          )
        ''');
      },
    );
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_db == null) return;

    final communityRows = await _db!.query(
      'messages',
      where: 'isBroadcast = 1',
      orderBy: 'timestamp ASC',
    );
    _communityMessages.clear();
    _communityMessages.addAll(communityRows.map((r) => ChatMessage.fromMap(r)));

    final privateRows = await _db!.query(
      'messages',
      where: 'isBroadcast = 0',
      orderBy: 'timestamp ASC',
    );
    _privateMessages.clear();
    for (final row in privateRows) {
      final targetId = row['targetDeviceId'] as String? ?? row['senderId'] as String;
      _privateMessages.putIfAbsent(targetId, () => []);
      _privateMessages[targetId]!.add(ChatMessage.fromMap(row));
    }

    notifyListeners();
  }

  Future<ChatMessage> sendCommunityMessage({
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.info,
    double? latitude,
    double? longitude,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      isBroadcast: true,
      isMine: true,
      latitude: latitude,
      longitude: longitude,
      status: MessageStatus.sent,
    );

    _communityMessages.add(message);
    notifyListeners();

    if (_db != null) {
      final map = message.toMap();
      map['targetDeviceId'] = '';
      await _db!.insert('messages', map);
    }

    return message;
  }

  Future<ChatMessage> sendPrivateMessage({
    required String senderId,
    required String senderName,
    required String targetDeviceId,
    required String content,
    List<String> routingPath = const [],
    double? latitude,
    double? longitude,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      content: content,
      isBroadcast: false,
      isMine: true,
      routingPath: routingPath,
      latitude: latitude,
      longitude: longitude,
      status: MessageStatus.sent,
    );

    _privateMessages.putIfAbsent(targetDeviceId, () => []);
    _privateMessages[targetDeviceId]!.add(message);
    notifyListeners();

    if (_db != null) {
      final map = message.toMap();
      map['targetDeviceId'] = targetDeviceId;
      await _db!.insert('messages', map);
    }

    return message;
  }

  Future<void> receiveMessage(ChatMessage message, {String? targetDeviceId}) async {
    if (message.isBroadcast) {
      // Check for duplicate
      if (_communityMessages.any((m) => m.id == message.id)) return;
      _communityMessages.add(message);
    } else {
      final key = targetDeviceId ?? message.senderId;
      _privateMessages.putIfAbsent(key, () => []);
      if (_privateMessages[key]!.any((m) => m.id == message.id)) return;
      _privateMessages[key]!.add(message);
    }
    notifyListeners();

    if (_db != null) {
      final map = message.toMap();
      map['targetDeviceId'] = targetDeviceId ?? '';
      await _db!.insert('messages', map, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    // Update in community
    final cIdx = _communityMessages.indexWhere((m) => m.id == messageId);
    if (cIdx >= 0) {
      _communityMessages[cIdx] = _communityMessages[cIdx].copyWith(status: status);
    }

    // Update in private
    for (final entry in _privateMessages.entries) {
      final pIdx = entry.value.indexWhere((m) => m.id == messageId);
      if (pIdx >= 0) {
        entry.value[pIdx] = entry.value[pIdx].copyWith(status: status);
      }
    }

    notifyListeners();

    if (_db != null) {
      await _db!.update(
        'messages',
        {'status': status.index},
        where: 'id = ?',
        whereArgs: [messageId],
      );
    }
  }

  Future<void> clearAllMessages() async {
    _communityMessages.clear();
    _privateMessages.clear();
    notifyListeners();
    if (_db != null) {
      await _db!.delete('messages');
    }
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }
}
