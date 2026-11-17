import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulse_ai/ai_service.dart';
import 'package:pulse_ai/models.dart';

void main() {
  final messages = [ChatMessage(id: 1, role: 'user', content: 'Hi', createdAt: DateTime.utc(2026))];
  test('missing key fails without network request', () async {
    final service = PulseAiService(client: MockClient((_) async => throw StateError('Unexpected request')));
    await expectLater(service.reply(apiKey: '', model: 'test', messages: messages, memories: []), throwsStateError);
    service.dispose();
  });
  test('sends context and parses response', () async {
    final service = PulseAiService(client: MockClient((request) async {
      expect(request.url.host, 'api.openai.com');
      expect(request.headers['Authorization'], 'Bearer example-key');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect((body['messages'] as List).length, 2);
      return http.Response(jsonEncode({'choices': [{'message': {'content': 'Hello back'}}]}), 200);
    }));
    expect(await service.reply(apiKey: 'example-key', model: 'test', messages: messages, memories: []), 'Hello back');
    service.dispose();
  });
  test('HTTP failures are surfaced', () async {
    final service = PulseAiService(client: MockClient((_) async => http.Response('{}', 401)));
    await expectLater(service.reply(apiKey: 'bad', model: 'test', messages: messages, memories: []), throwsStateError);
    service.dispose();
  });
}
