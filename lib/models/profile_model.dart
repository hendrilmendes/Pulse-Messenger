class UserProfile {
  final String uid;
  final String name;
  final String username;
  final String avatar;

  UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['username'], // ou `uid`, conforme seu endpoint
    name: json['name'],
    username: json['username'],
    avatar: json['avatar'],
  );
}
