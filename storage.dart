import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class PulseStorage {
  PulseStorage._(this.db);
  final Database db;
  static Future<PulseStorage> open() async {
    final path = join(await getDatabasesPath(), 'pulse_ai_v1.db');
    final db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT NOT NULL, content TEXT NOT NULL, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE memories (id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT NOT NULL, created_at TEXT NOT NULL)');
    });
    return PulseStorage._(db);
  }
  Future<List<ChatMessage>> messages() async =>
      (await db.query('messages', orderBy: 'id ASC')).map(ChatMessage.fromMap).toList();
  Future<List<MemoryItem>> memories() async =>
      (await db.query('memories', orderBy: 'id DESC')).map(MemoryItem.fromMap).toList();
  Future<void> addMessage(String role, String content) async {
    if (!['user', 'assistant'].contains(role)) throw ArgumentError('Invalid role');
    await db.insert('messages', {'role': role, 'content': content, 'created_at': DateTime.now().toUtc().toIso8601String()});
  }
  Future<void> addMemory(String content) async {
    final cleaned = content.trim();
    if (cleaned.isEmpty) throw ArgumentError('Empty memory');
    await db.insert('memories', {'content': cleaned, 'created_at': DateTime.now().toUtc().toIso8601String()});
  }
  Future<void> removeMemory(int id) async { await db.delete('memories', where: 'id = ?', whereArgs: [id]); }
  Future<void> clearMessages() async { await db.delete('messages'); }
  Future<void> close() => db.close();
}
