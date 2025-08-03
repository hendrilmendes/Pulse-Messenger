import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/comments/comments.dart';
import 'package:social/screens/shared/shared.dart';
import 'package:social/widgets/video/video_player.dart';

class PostDetailsScreen extends StatelessWidget {
  final String postId;
  final _auth = FirebaseAuth.instance;

  PostDetailsScreen({required this.postId, super.key});

  Future<void> _likePost(String postId, String userId) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.data() as Map<String, dynamic>;
      final likesData = postData['likes'];
      List<String> likes;

      if (likesData is List) {
        likes = List<String>.from(likesData.map((e) => e.toString()));
      } else {
        likes = [];
      }

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      transaction.update(postRef, {'likes': likes});
    });
  }

  void _showComments(BuildContext context, String postOwnerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    width: MediaQuery.of(context).size.width,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: CommentsScreen(
                        postId: postId,
                        postOwnerId: postOwnerId,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    width: MediaQuery.of(context).size.width,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: ShareOptionsScreen(postId: postId),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<int> _getCommentsCount(String postId) async {
    final commentsSnapshot =
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .get();

    return commentsSnapshot.size;
  }

  Future<String> _getPostOwnerId(String postId) async {
    final postSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    final postData = postSnapshot.data() as Map<String, dynamic>;
    return postData['user_id'] ?? '';
  }

  bool _isVideo(String url) {
    return url.contains(".mp4") || url.contains(".mov") || url.contains(".avi");
  }

  Future<bool> isPostSaved(String postId, String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final savedPosts = userDoc.data()?['saved_posts'] as List? ?? [];
    return savedPosts.contains(postId);
  }

  Future<void> _savePost(String postId, String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        List<String> savedPosts = [];
        if (userSnapshot.exists) {
          savedPosts = List<String>.from(
            userSnapshot.data()?['saved_posts'] ?? [],
          );
        }
        if (savedPosts.contains(postId)) {
          savedPosts.remove(postId);
        } else {
          savedPosts.add(postId);
        }

        transaction.update(userRef, {'saved_posts': savedPosts});
      });
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao salvar postagem: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.55,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('Post não encontrado.'));
                    }

                    final postData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final fileUrl = postData['file_url'] ?? '';
                    final content = postData['content'] ?? 'Sem legenda';

                    if (fileUrl.isNotEmpty) {
                      return _isVideo(fileUrl)
                          ? AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VideoPlayerWidget(url: fileUrl),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: fileUrl,
                              fit: BoxFit.cover,
                            ),
                          );
                    } else {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            content,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            pinned: true,
            backgroundColor: Colors.black,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('Post não encontrado.'));
                    }

                    final postData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final userPhoto = postData['user_photo'] ?? '';
                    final username =
                        postData['username'] ?? 'Usuário desconhecido';
                    final content = postData['content'] ?? 'Sem legenda';
                    final likesData = postData['likes'];
                    final likes =
                        (likesData is List
                                ? List<String>.from(
                                  likesData.map((e) => e.toString()),
                                )
                                : [])
                            .toList();
                    final isLiked = likes.contains(userId);

                    return FutureBuilder<bool>(
                      future: isPostSaved(postId, userId),
                      builder: (context, savedSnapshot) {
                        final isSaved = savedSnapshot.data ?? false;

                        return FutureBuilder<int>(
                          future: _getCommentsCount(postId),
                          builder: (context, commentsSnapshot) {
                            final commentsCount = commentsSnapshot.data ?? 0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundImage:
                                          userPhoto.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                userPhoto,
                                              )
                                              : null,
                                      child:
                                          userPhoto.isEmpty
                                              ? const Icon(Icons.person)
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(
                                        isSaved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isSaved ? Colors.blue : null,
                                      ),
                                      onPressed: () {
                                        _savePost(postId, userId);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked ? Colors.red : null,
                                      ),
                                      onPressed: () {
                                        _likePost(postId, userId);
                                      },
                                    ),
                                    Text('${likes.length} curtidas'),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.comment),
                                      onPressed: () async {
                                        final postOwnerId =
                                            await _getPostOwnerId(postId);
                                        // ignore: use_build_context_synchronously
                                        _showComments(context, postOwnerId);
                                      },
                                    ),
                                    Text('$commentsCount comentários'),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () {
                                        _showShareOptions(context);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
