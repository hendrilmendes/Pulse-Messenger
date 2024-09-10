import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/providers/auth_provider.dart';
import 'package:social/screens/post_details/post_details.dart';
import 'package:social/screens/settings/settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(
          postId: postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('Usuário não encontrado.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Username';
          final profilePictureUrl = userData['profile_picture'] ?? '';
          final initials = getInitials(username);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.teal.shade100,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal,
                      backgroundImage: profilePictureUrl.isNotEmpty
                          ? NetworkImage(profilePictureUrl)
                          : null,
                      child: profilePictureUrl.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData['bio'] ?? 'Adicionar uma bio...',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .where('user_id', isEqualTo: userId)
                                    .snapshots(),
                                builder: (context, postSnapshot) {
                                  if (postSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  final postCount = postSnapshot.hasData
                                      ? postSnapshot.data!.docs.length
                                      : 0;

                                  return _buildStatColumn(
                                      'Posts', postCount.toString());
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('following')
                                    .doc(
                                        userId)
                                    .collection(
                                        'userFollowing')
                                    .snapshots(),
                                builder: (context, followingSnapshot) {
                                  if (followingSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator.adaptive());
                                  }

                                  final followingCount =
                                      followingSnapshot.hasData
                                          ? followingSnapshot.data!.docs.length
                                          : 0;

                                  return _buildStatColumn(
                                      'Seguindo', followingCount.toString());
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('followers')
                                    .doc(
                                        userId)
                                    .collection(
                                        'userFollowers')
                                    .snapshots(),
                                builder: (context, followerSnapshot) {
                                  if (followerSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  final followerCount = followerSnapshot.hasData
                                      ? followerSnapshot.data!.docs.length
                                      : 0;

                                  return _buildStatColumn(
                                      'Seguidores', followerCount.toString());
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // User's Posts
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('user_id', isEqualTo: userId)
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Nenhuma postagem.'));
                    }

                    final posts = snapshot.data!.docs;

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final postData = post.data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () => _openPost(context, post.id),
                          child: postData.containsKey('image_url')
                              ? Image.network(
                                  postData['image_url'],
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

Widget buildStatColumn(String label, String count) {
  return Column(
    children: [
      Text(
        count,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );
}
