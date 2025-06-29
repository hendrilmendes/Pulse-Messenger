class Conversation {
  final String id;
  final String name;
  final String lastMessage;
  final String updatedAt;
  final String avatarUrl;

  Conversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.updatedAt,
    required this.avatarUrl,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      name: json['name'],
      lastMessage: json['last_message'] ?? '',
      updatedAt: json['updated_at'],
      avatarUrl: json['avatar_url'] ?? 'https://i.pravatar.cc/300', // padrão
    );
  }
}
