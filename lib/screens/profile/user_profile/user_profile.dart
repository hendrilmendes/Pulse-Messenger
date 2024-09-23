// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/chat/chat_details/chat_details.dart';
import 'package:social/screens/post/post_details/post_details.dart';
import 'package:social/widgets/user/shimmer_user.dart';
import 'package:video_thumbnail/video_thumbnail.dart'; // Adicione isso
import 'package:path_provider/path_provider.dart'; // Adicione isso

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;

  const UserProfileScreen(
      {required this.userId, required this.username, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isFollowing = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    Future.wait([_checkIfFollowing(), _fetchCounts()]);
  }

  Future<void> _checkIfFollowing() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final followingDoc = await FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.userId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();

    setState(() {
      isFollowing = followingDoc.exists;
    });
  }

  Future<void> _fetchCounts() async {
    // Fetch post count
    final postSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('user_id', isEqualTo: widget.userId)
        .get();

    final mediaPostCount = postSnapshot.docs.where((doc) {
      final postData = doc.data() as Map<String, dynamic>?;
      final fileUrl = postData?['file_url'] ?? '';
      return fileUrl.isNotEmpty &&
          (fileUrl.contains('.jpg') ||
              fileUrl.contains('.png') ||
              fileUrl.contains('.mp4'));
    }).length;

    setState(() {
      postCount = mediaPostCount;
    });

    // Fetch follower count
    final followerSnapshot = await FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.userId)
        .collection('userFollowers')
        .get();

    setState(() {
      followerCount = followerSnapshot.size;
    });

    // Fetch following count
    final followingSnapshot = await FirebaseFirestore.instance
        .collection('following')
        .doc(widget.userId)
        .collection('userFollowing')
        .get();

    setState(() {
      followingCount = followingSnapshot.size;
    });
  }

  Future<void> _toggleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    if (isFollowing) {
      // Deixar de seguir: Remova o usuário das listas de seguidores/seguidos
      await FirebaseFirestore.instance
          .collection('followers')
          .doc(widget.userId)
          .collection('userFollowers')
          .doc(currentUserId)
          .delete();

      await FirebaseFirestore.instance
          .collection('following')
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(widget.userId)
          .delete();
    } else {
      // Seguir: Adiciona o usuário às listas de seguidores/seguidos
      await FirebaseFirestore.instance
          .collection('followers')
          .doc(widget.userId)
          .collection('userFollowers')
          .doc(currentUserId)
          .set({'followed_at': Timestamp.now()});

      await FirebaseFirestore.instance
          .collection('following')
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(widget.userId)
          .set({'followed_at': Timestamp.now()});

      // Adiciona notificação de "seguir"
      await addFollowNotification(widget.userId);
    }

    // Atualiza o estado
    setState(() {
      isFollowing = !isFollowing;
    });

    // Atualiza contagens
    await _fetchCounts();
  }

  Future<void> addFollowNotification(String followedUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown User';

    if (currentUserId == null) return;

    // Adiciona notificação ao Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'follow',
      'from_user': currentUserName,
      'from_user_id': currentUserId,
      'from_user_profile_picture':
          FirebaseAuth.instance.currentUser?.photoURL ?? '',
      'user_id': followedUserId,
      'created_at': Timestamp.now(),
    });
  }

  void _startChat(BuildContext context, String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Você precisa estar logado para iniciar um bate-papo.')),
      );
      return;
    }

    final chatId = [currentUserId, userId]..sort();
    final chatIdString = chatId.join('-');

    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatIdString)
        .get();

    bool isGroup =
        chatQuery.data()?['isGroup'] ?? false; // Check if it's a group chat

    if (chatQuery.exists) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatIdString,
            userId: userId,
            isGroup: isGroup, // Pass isGroup here
          ),
        ),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatIdString)
          .set({
        'participants': [currentUserId, userId],
        'last_message': '',
        'last_message_time': Timestamp.now(),
        'isGroup': false, // Default to false for individual chats
      });

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatIdString,
            userId: userId,
            isGroup: false,
          ),
        ),
      );
    }
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

  bool _isVideo(String url) {
    return url.contains(".mp4") || url.contains(".mov") || url.contains(".avi");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                children: [
                  ShimmerUserLoader(
                      height: 100,
                      width: 100,
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  SizedBox(height: 16),
                  ShimmerUserLoader(height: 20, width: 150),
                  SizedBox(height: 8),
                  ShimmerUserLoader(height: 20, width: 200),
                ],
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Usuário não encontrado.'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userName = userData['username'] ?? 'Unknown';
            final userProfilePicture = userData['profile_picture'] ?? '';
            final userBio = userData['bio'] ?? 'Bio não disponível.';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userProfilePicture.isNotEmpty
                          ? CachedNetworkImageProvider(userProfilePicture)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: userProfilePicture.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userBio,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInfoColumn(context, 'Posts', postCount),
                                _buildInfoColumn(
                                    context, 'Seguidores', followerCount),
                                _buildInfoColumn(
                                    context, 'Seguindo', followingCount),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _toggleFollow,
                                    child: Text(
                                        isFollowing ? 'Seguindo' : 'Seguir'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _startChat(context, widget.userId),
                                    child: const Text('Chat'),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('user_id', isEqualTo: widget.userId)
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }

                      // Filtra os posts que possuem um 'file_url' válido
                      final postsWithMedia = snapshot.data!.docs.where((post) {
                        final postData = post.data() as Map<String, dynamic>?;
                        final postImage = postData?['file_url'] ?? '';
                        return postImage.isNotEmpty;
                      }).toList();

                      if (postsWithMedia.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum postagem encontrada.',
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: postsWithMedia.length,
                        itemBuilder: (context, index) {
                          final post = postsWithMedia[index];
                          final postData = post.data() as Map<String, dynamic>?;
                          final postImage = postData?['file_url'] ?? '';
                          final isVideo = _isVideo(postImage);

                          return GestureDetector(
                            onTap: () => _openPost(context, post.id),
                            child: Stack(
                              children: [
                                isVideo
                                    ? FutureBuilder<String?>(
                                        future:
                                            _generateVideoThumbnail(postImage),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          final thumbnailPath = snapshot.data;
                                          return Container(
                                            decoration: BoxDecoration(
                                              image: thumbnailPath != null
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                          File(thumbnailPath)),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: CachedNetworkImageProvider(
                                                postImage),
                                            fit: BoxFit.cover,
                                          ),
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
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
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String title, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(),
        ),
      ],
    );
  }
}
