import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/comments/comments.dart';
import 'package:social/screens/shared/shared.dart';
import 'package:social/widgets/video/video_player.dart';

class PostDetailsScreen extends StatelessWidget {
  final String postId;

  const PostDetailsScreen({required this.postId, super.key});

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
                          postId: postId, postOwnerId: postOwnerId),
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
    final commentsSnapshot = await FirebaseFirestore.instance
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

  @override
  Widget build(BuildContext context) {
    const userId = 'user_current_id';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.55,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('Post não encontrado.'));
                    }

                    final postData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final fileUrl = postData['file_url'] ?? '';

                    // Verificar se é um vídeo ou imagem
                    return fileUrl.isNotEmpty
                        ? _isVideo(fileUrl)
                            ? AspectRatio(
                                aspectRatio: 16 / 9,
                                child: VideoPlayerWidget(url: fileUrl),
                              )
                            : InteractiveViewer(
                                child: Image(
                                  image: CachedNetworkImageProvider(fileUrl),
                                  fit: BoxFit.contain,
                                ),
                              )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
            pinned: true,
            backgroundColor: Colors.black,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                            child: Text('Post não encontrado.'));
                      }

                      // Conteúdo do post (não alterado)
                      final postData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final userPhoto = postData['user_photo'] ?? '';
                      final username =
                          postData['username'] ?? 'Usuário desconhecido';
                      final content = postData['content'] ?? 'Sem legenda';
                      final likesData = postData['likes'];
                      final likes = (likesData is List
                              ? List<String>.from(
                                  likesData.map((e) => e.toString()))
                              : [])
                          .toList();
                      final isLiked = likes.contains(userId);

                      return FutureBuilder<int>(
                        future: _getCommentsCount(postId),
                        builder: (context, commentsSnapshot) {
                          final commentsCount = commentsSnapshot.data ?? 0;

                          if (commentsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: userPhoto.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              userPhoto)
                                          : null,
                                      child: userPhoto.isEmpty
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
                                      icon: const Icon(Icons.bookmark_border),
                                      onPressed: () {
                                        // Add bookmark logic here
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
                                    const SizedBox(width: 8),
                                    Text(
                                      '${likes.length} curtidas',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '$commentsCount comentários',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () =>
                                          _showShareOptions(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<String>(
        future: _getPostOwnerId(postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final postOwnerId = snapshot.data!;

          return FloatingActionButton(
            onPressed: () => _showComments(context, postOwnerId),
            child: const Icon(Icons.comment),
          );
        },
      ),
    );
  }
}
