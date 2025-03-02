import 'package:chat_ai/models/chat_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:chat_ai/models/message_model.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_messages.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        text TEXT NOT NULL,
        file_url TEXT,
        file_name TEXT,
        time TEXT NOT NULL,
        is_from_me INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_text TEXT NOT NULL,
        avatar_color INTEGER NOT NULL,
        avatar_url TEXT,
        last_message TEXT,
        last_message_time TEXT,
        last_timestamp INTEGER
      )
    ''');

    // Insert sample users with avatars
    final sampleUsers = [
      {
        'id': '1',
        'name': 'Виктор Волков',
        'avatar_text': 'ВВ',
        'avatar_color': Colors.blue.value,
        'avatar_url': 'https://i.pravatar.cc/150?img=1',
        'last_message': '',
        'last_message_time': '',
        'last_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': '2',
        'name': 'Саша Алексеев',
        'avatar_text': 'СА',
        'avatar_color': Colors.orange.value,
        'avatar_url': 'https://i.pravatar.cc/150?img=2',
        'last_message': '',
        'last_message_time': '',
        'last_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': '3',
        'name': 'Мария Петрова',
        'avatar_text': 'МП',
        'avatar_color': Colors.purple.value,
        'avatar_url': 'https://i.pravatar.cc/150?img=3',
        'last_message': '',
        'last_message_time': '',
        'last_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (var user in sampleUsers) {
      await db.insert('users', user);
    }

    // Insert sample messages
    final now = DateTime.now();
    final sampleMessages = [
      {
        'id': '1',
        'chat_id': '1',
        'text': 'Привет! Как дела?',
        'time': '10:30',
        'is_from_me': 0,
        'timestamp':
            now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'type': 'text'
      },
      {
        'id': '2',
        'chat_id': '1',
        'text': 'Все хорошо, спасибо!',
        'time': '10:35',
        'is_from_me': 1,
        'timestamp':
            now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'type': 'text'
      },
      {
        'id': '3',
        'chat_id': '2',
        'text': 'Привет! Встретимся завтра?',
        'time': '15:20',
        'is_from_me': 0,
        'timestamp':
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        'type': 'text'
      },
      {
        'id': '4',
        'chat_id': '3',
        'text': 'Документы готовы',
        'time': '16:45',
        'is_from_me': 1,
        'timestamp':
            now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
        'type': 'text'
      },
    ];

    for (var message in sampleMessages) {
      await db.insert('messages', message);
    }
  }

  Future<void> insertMessage(String chatId, Message message) async {
    final Database db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'chat_id': chatId,
        'text': message.text,
        'file_url': message.fileUrl,
        'file_name': message.fileName,
        'time': message.time,
        'is_from_me': message.isFromMe ? 1 : 0,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'type': message.type.toString().split('.').last,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Message>> getMessages(String chatId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) {
      return Message(
        id: map['id'],
        text: map['text'],
        fileUrl: map['file_url'],
        fileName: map['file_name'],
        time: map['time'],
        isFromMe: map['is_from_me'] == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        type: MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'],
        ),
      );
    }).toList();
  }

  Future<void> deleteMessage(String messageId) async {
    final Database db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> clearChat(String chatId) async {
    final Database db = await database;
    await db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  Future<Message?> getLastMessage(String chatId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Message(
      id: maps[0]['id'],
      text: maps[0]['text'],
      fileUrl: maps[0]['file_url'],
      fileName: maps[0]['file_name'],
      time: maps[0]['time'],
      isFromMe: maps[0]['is_from_me'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(maps[0]['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == maps[0]['type'],
      ),
    );
  }

  Future<List<ChatModel>> getChatsWithLastMessages() async {
    final Database db = await database;

    // Get all users with their last messages
    final List<Map<String, dynamic>> users = await db.rawQuery('''
      SELECT 
        u.*,
        m.text as last_message,
        m.time as last_message_time,
        m.timestamp as last_timestamp,
        m.type as message_type
      FROM users u
      LEFT JOIN (
        SELECT 
          chat_id,
          text,
          time,
          timestamp,
          type,
          ROW_NUMBER() OVER (PARTITION BY chat_id ORDER BY timestamp DESC) as rn
        FROM messages
      ) m ON m.chat_id = u.id AND m.rn = 1
      ORDER BY COALESCE(m.timestamp, 0) DESC
    ''');

    return users.map((user) {
      String messagePreview = '';
      if (user['last_message'] != null) {
        if (user['message_type'] == 'image') {
          messagePreview = '📷 Photo';
        } else if (user['message_type'] == 'audio') {
          messagePreview = '🎵 Voice message';
        } else if (user['message_type'] == 'file') {
          messagePreview = '📎 File';
        } else {
          messagePreview = user['last_message'];
        }
      }

      return ChatModel(
        id: user['id'],
        name: user['name'],
        lastMessage: messagePreview,
        time: user['last_message_time'] ?? '',
        avatarText: user['avatar_text'],
        avatarColor: Color(user['avatar_color']),
        avatarUrl: user['avatar_url'],
        timestamp: user['last_timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(user['last_timestamp'])
            : DateTime(0),
      );
    }).toList();
  }

  Future<void> addUser(ChatModel user) async {
    final Database db = await database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'avatar_text': user.avatarText,
        'avatar_color': user.avatarColor.value,
        'avatar_url': user.avatarUrl,
        'last_message': user.lastMessage,
        'last_message_time': user.time,
        'last_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteChat(String chatId) async {
    final Database db = await database;
    await db.transaction((txn) async {
      // Delete all messages for this chat
      await txn.delete(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      // Delete the user/chat
      await txn.delete(
        'users',
        where: 'id = ?',
        whereArgs: [chatId],
      );
    });
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_messages.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
