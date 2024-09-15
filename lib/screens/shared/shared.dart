import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ShareOptionsScreen extends StatelessWidget {
  final String postId;

  const ShareOptionsScreen({required this.postId, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _fetchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        final users = snapshot.data ?? [];

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.profilePicture),
              ),
              title: Text(user.username),
              trailing: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _sharePost(user.id); // Método para compartilhar o post
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<User>> _fetchUsers() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return usersSnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<void> _sharePost(String recipientId) async {
    if (kDebugMode) {
      print('Sharing post with recipient ID: $recipientId');
    }
    try {
      await FirebaseFirestore.instance.collection('shared_posts').add({
        'post_id': postId,
        'recipient_id': recipientId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('Post shared successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing post: $e');
      }
      throw Exception('Erro ao compartilhar postagem: $e');
    }
  }
}

class User {
  final String id;
  final String username;
  final String profilePicture;

  User({
    required this.id,
    required this.username,
    required this.profilePicture,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: data['user_id'] ?? '',
      username: data['username'] ?? '',
      profilePicture: data['profile_picture'] ?? '',
    );
  }
}
