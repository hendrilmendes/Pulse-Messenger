class PostModel {
  final String author;
  final String username;
  final String avatar;
  final String? image;
  final String caption;
  final int reactions;
  final int comments;
  final DateTime createdAt;

  PostModel({
    required this.author,
    required this.username,
    required this.avatar,
    this.image,
    required this.caption,
    required this.reactions,
    required this.comments,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      author: json['author'],
      username: json['username'],
      avatar: json['avatar'],
      image: json['image'],
      caption: json['caption'],
      reactions: json['reactions'],
      comments: json['comments'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
