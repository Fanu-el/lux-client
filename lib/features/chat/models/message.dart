enum MessageRole { user, assistant }

class Message {
  const Message({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime? createdAt;

  bool get isUser => role == MessageRole.user;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        role: (json['role'] as String?)?.toUpperCase() == 'USER'
            ? MessageRole.user
            : MessageRole.assistant,
        content: (json['content'] as String?) ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
