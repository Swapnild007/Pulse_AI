import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Browser-local persistence. Browser storage can be cleared by the user/browser.
class PulseStorage {
  PulseStorage._(this.prefs);
  final SharedPreferences prefs;
  static Future<PulseStorage> open() async => PulseStorage._(await SharedPreferences.getInstance());
  List<Map<String, dynamic>> _read(String key) =>
      (jsonDecode(prefs.getString(key) ?? '[]') as List).cast<Map<String, dynamic>>();
  Future<List<ChatMessage>> messages() async => _read('pulse_messages')
      .map((x) => ChatMessage.fromMap(x)).toList();
  Future<List<MemoryItem>> memories() async => _read('pulse_memories')
      .map((x) => MemoryItem.fromMap(x)).toList();
  Future<void> addMessage(String role, String content) async {
    if (!['user', 'assistant'].contains(role)) throw ArgumentError('Invalid role');
    final rows = _read('pulse_messages');
    rows.add({'id': _nextId(rows), 'role': role, 'content': content,
      'created_at': DateTime.now().toUtc().toIso8601String()});
    await prefs.setString('pulse_messages', jsonEncode(rows));
  }
  Future<void> addMemory(String content) async {
    if (content.trim().isEmpty) throw ArgumentError('Empty memory');
    final rows = _read('pulse_memories');
    rows.add({'id': _nextId(rows), 'content': content.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String()});
    await prefs.setString('pulse_memories', jsonEncode(rows));
  }
  int _nextId(List<Map<String, dynamic>> rows) => rows.fold<int>(0, (max, row) =>
      (row['id'] as int) > max ? row['id'] as int : max) + 1;
  Future<void> removeMemory(int id) async {
    final rows = _read('pulse_memories')..removeWhere((x) => x['id'] == id);
    await prefs.setString('pulse_memories', jsonEncode(rows));
  }
  Future<void> clearMessages() => prefs.remove('pulse_messages');
  Future<void> close() async {}
}
