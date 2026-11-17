import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class PulseAiService {
  PulseAiService({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;
  Future<String> reply({required String apiKey, required String model,
    required List<ChatMessage> messages, required List<MemoryItem> memories}) async {
    if (apiKey.trim().isEmpty) throw StateError('Add your API key in Settings.');
    final context = messages.length > 24 ? messages.sublist(messages.length - 24) : messages;
    final response = await client.post(Uri.https('api.openai.com', '/v1/chat/completions'),
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': model, 'messages': [
        {'role': 'system', 'content': buildSystemPrompt(memories)},
        ...context.map((m) => {'role': m.role, 'content': m.content}),
      ]})).timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) {
      throw StateError('AI request failed (${response.statusCode}). Check your API key, model and connection.');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) throw StateError('Empty AI response.');
    final content = (choices.first as Map<String, dynamic>)['message']['content'];
    if (content is! String || content.trim().isEmpty) throw StateError('Empty AI response.');
    return content.trim();
  }
  void dispose() => client.close();
}
