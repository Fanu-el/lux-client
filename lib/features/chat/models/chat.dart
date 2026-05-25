class Chat {
  const Chat({required this.id, required this.title, this.updatedAt});

  final String id;
  final String title;
  final DateTime? updatedAt;

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? 'New chat',
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  Chat copyWith({String? title}) => Chat(
        id: id,
        title: title ?? this.title,
        updatedAt: updatedAt,
      );
}
