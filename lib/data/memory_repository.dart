import '../models/chat_message.dart';

abstract interface class MemoryRepository {
  Future<void> initialize();
  Future<void> saveMessage(ChatMessage message);
  Future<List<ChatMessage>> getRecentMessages({int limit = 50, String threadId = 'default'});
  Future<List<ChatMessage>> searchMemory(String query, {int limit = 8});
  Future<void> clearThread(String threadId);
  Future<void> close();
}
