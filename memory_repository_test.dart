import 'package:flutter_test/flutter_test.dart';
import 'package:rocky_companion/data/memory_repository.dart';
import 'package:rocky_companion/models/chat_message.dart';

class FakeMemoryRepository implements MemoryRepository {
  final List<ChatMessage> data = [];
  @override Future<void> initialize() async {}
  @override Future<void> close() async {}
  @override Future<void> saveMessage(ChatMessage message) async => data.add(message);
  @override Future<void> clearThread(String threadId) async => data.removeWhere((m) => m.threadId == threadId);
  @override Future<List<ChatMessage>> getRecentMessages({int limit = 50, String threadId = 'default'}) async => data.where((m) => m.threadId == threadId).take(limit).toList();
  @override Future<List<ChatMessage>> searchMemory(String query, {int limit = 8}) async => data.where((m) => m.text.toLowerCase().contains(query.toLowerCase())).take(limit).toList();
}

void main() {
  test('repository abstraction persists and searches messages', () async {
    final repo = FakeMemoryRepository();
    await repo.initialize();
    final message = ChatMessage(id: '1', role: MessageRole.user, text: 'I am building Rocky', createdAt: DateTime.now());
    await repo.saveMessage(message);
    expect((await repo.getRecentMessages()).single.text, 'I am building Rocky');
    expect((await repo.searchMemory('rocky')).single.id, '1');
  });
}
