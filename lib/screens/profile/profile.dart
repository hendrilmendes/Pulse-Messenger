import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_thumbnail/video_thumbnail.dart'; // Adicione isso
import 'package:social/providers/auth_provider.dart';
import 'package:social/screens/post_details/post_details.dart';
import 'package:social/screens/settings/settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PostDetailsScreen(
          postId: postId,
        ),
      ),
    );
  }

  Future<String?> _generateVideoThumbnail(String videoUrl) async {
    final filePath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 512,
      quality: 100,
    );
    return filePath;
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
        title: const Text(
          'Perfil',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal,
                      backgroundImage: profilePictureUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profilePictureUrl)
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
                            userData['bio'] ?? 'Sem biografia...',
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
                                        child: CircularProgressIndicator
                                            .adaptive());
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
                                    .doc(userId)
                                    .collection('userFollowing')
                                    .snapshots(),
                                builder: (context, followingSnapshot) {
                                  if (followingSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator
                                            .adaptive());
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
                                    .doc(userId)
                                    .collection('userFollowers')
                                    .snapshots(),
                                builder: (context, followerSnapshot) {
                                  if (followerSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator
                                            .adaptive());
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
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Nenhuma postagem.'));
                    }

                    final posts = snapshot.data!.docs;

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final postData = post.data() as Map<String, dynamic>?;
                        final postImage = postData?['file_url'] ?? '';
                        final isVideo = _isVideo(postImage);

                        return GestureDetector(
                          onTap: () => _openPost(context, post.id),
                          child: Stack(
                            children: [
                              FutureBuilder<String?>(
                                future: isVideo ? _generateVideoThumbnail(postImage) : null,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final thumbnailPath = snapshot.data;

                                  return Container(
                                    decoration: BoxDecoration(
                                      image: postImage.isNotEmpty
                                          ? DecorationImage(
                                              image: isVideo && thumbnailPath != null
                                                  ? FileImage(File(thumbnailPath))
                                                  : CachedNetworkImageProvider(postImage),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                  );
                                },
                              ),
                              if (isVideo)
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
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

  bool _isVideo(String url) {
    return url.contains(".mp4") || url.contains(".mov") || url.contains(".avi");
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
