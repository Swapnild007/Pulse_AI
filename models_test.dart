import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ai/models.dart';

void main() {
  test('message mapping preserves fields', () {
    final message = ChatMessage.fromMap({
      'id': 4, 'role': 'user', 'content': 'Hello', 'created_at': '2026-11-17T10:00:00Z'
    });
    expect(message.id, 4);
    expect(message.role, 'user');
    expect(message.content, 'Hello');
  });
  test('empty memory prompt is explicit', () {
    expect(buildSystemPrompt([]), contains('(none)'));
  });
  test('approved memory is included', () {
    final memory = MemoryItem(id: 1, content: 'Prefers concise answers', createdAt: DateTime.utc(2026));
    expect(buildSystemPrompt([memory]), contains('Prefers concise answers'));
  });
}
