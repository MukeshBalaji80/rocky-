import 'package:intl/intl.dart';

enum MessageRole { user, rocky, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.threadId = 'default',
  });

  final String id;
  final MessageRole role;
  final String text;
  final DateTime createdAt;
  final String threadId;

  String get timeLabel => DateFormat('HH:mm').format(createdAt);

  Map<String, Object?> toMap() => {
        'id': id,
        'role': role.name,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        'thread_id': threadId,
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: map['id']! as String,
        role: MessageRole.values.byName(map['role']! as String),
        text: map['text']! as String,
        createdAt: DateTime.parse(map['created_at']! as String),
        threadId: (map['thread_id'] as String?) ?? 'default',
      );
}
