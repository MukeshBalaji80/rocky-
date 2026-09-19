import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';
import 'memory_repository.dart';

class SqliteMemoryRepository implements MemoryRepository {
  Database? _db;

  @override
  Future<void> initialize() async {
    if (_db != null) return;
    final dbPath = join(await getDatabasesPath(), 'rocky_memory.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at TEXT NOT NULL,
            thread_id TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_messages_thread_time ON messages(thread_id, created_at)');
      },
    );
  }

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('MemoryRepository has not been initialized.');
    }
    return database;
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    await db.insert('messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<ChatMessage>> getRecentMessages({int limit = 50, String threadId = 'default'}) async {
    final rows = await db.query(
      'messages',
      where: 'thread_id = ?',
      whereArgs: [threadId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.reversed.map(ChatMessage.fromMap).toList();
  }

  @override
  Future<List<ChatMessage>> searchMemory(String query, {int limit = 8}) async {
    final rows = await db.query(
      'messages',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  @override
  Future<void> clearThread(String threadId) async {
    await db.delete('messages', where: 'thread_id = ?', whereArgs: [threadId]);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
