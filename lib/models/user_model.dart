class UserModel {
  final String name;
  final String username;
  final String avatarUrl;

  UserModel({required this.name, required this.username, required this.avatarUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      username: json['username'],
      avatarUrl: json['avatar'],
    );
  }
}
