import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/comments/comments.dart';

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
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('Post não encontrado.'));
                    }

                    final postData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final imageUrl = postData['file_url'] ?? '';

                    return imageUrl.isNotEmpty
                        ? InteractiveViewer(
                            child: Image.network(imageUrl, fit: BoxFit.contain),
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
                      return const Center(child: CircularProgressIndicator());
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
                    final likes = (likesData is List
                            ? List<String>.from(
                                likesData.map((e) => e.toString()))
                            : [])
                        .toList();
                    final comments =
                        postData['comments'] as List<dynamic>? ?? [];
                    final commentsCount = comments.length;
                    final isLiked = likes.contains(userId);
                    final postOwnerId = postData['user_id'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: userPhoto.isNotEmpty
                                    ? NetworkImage(userPhoto)
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
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  // Add share logic here
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: FloatingActionButton.extended(
                              onPressed: () =>
                                  _showComments(context, postOwnerId),
                              label: const Text('Comentários'),
                              icon: const Icon(Icons.comment),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
