class Status {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String? caption;
  final String? imageUrl;
  final DateTime createdAt;
  late final bool viewed;

  Status({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    this.caption,
    this.imageUrl,
    required this.createdAt,
    required this.viewed,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Agora há pouco';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} d atrás';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userPhotoUrl: json['user_photo_url'],
      caption: json['caption'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      viewed: json['viewed'] ?? false,
    );
  }
}