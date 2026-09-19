import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

class AiClient {
  AiClient({
    required this.baseUrl,
    required this.model,
    this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String model;
  final String? apiKey;
  final http.Client _client;

  Future<String> generateReply({
    required List<ChatMessage> history,
    required String userText,
    required String personalityPrompt,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': personalityPrompt},
      ...history.map((m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.text,
          }),
      {'role': 'user', 'content': userText},
    ];

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${apiKey!.trim()}';
    }

    final response = await _client.post(
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions'),
      headers: headers,
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.75,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI backend returned HTTP ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final content = choices?.isNotEmpty == true
        ? ((choices!.first as Map<String, dynamic>)['message'] as Map<String, dynamic>)['content']
        : null;

    if (content is! String || content.trim().isEmpty) {
      throw Exception('AI backend returned no assistant message.');
    }
    return content.trim();
  }

  void dispose() => _client.close();
}
