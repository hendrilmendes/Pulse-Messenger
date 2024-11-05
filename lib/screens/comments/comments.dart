import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/widgets/comments/action_bar.dart';
import 'package:social/widgets/comments/shimmer_comments.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId; // Id do dono da postagem
  const CommentsScreen(
      {super.key, required this.postId, required this.postOwnerId});

  @override
  // ignore: library_private_types_in_public_api
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  void _addComment() async {
    if (_commentController.text.isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Obtém as informações do usuário da coleção 'users'
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            final username = userData['username'] ?? 'Anônimo';
            final userPhoto = userData['profile_picture'] ?? '';

            // Adiciona o comentário ao Firestore
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .add({
              'user_id': currentUser.uid,
              'username': username,
              'user_photo': userPhoto,
              'comment': _commentController.text,
              'created_at': Timestamp.now(),
              'likes': [],
            });

            // Envia a notificação para o dono da postagem
            await FirebaseFirestore.instance.collection('notifications').add({
              'user_id': widget.postOwnerId,
              'from_user_id': currentUser.uid,
              'post_id': widget.postId,
              'type': 'comment',
              'created_at': Timestamp.now(),
              'is_notified': false,
            });

            _commentController.clear();
          } else {
            if (kDebugMode) {
              print('Dados do usuário não encontrados.');
            }
          }
        }
      }
    }
  }

  Future<void> _likeComment(String commentId, String userId) async {
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) return;

      final commentData = commentSnapshot.data() as Map<String, dynamic>;
      final likesData = commentData['likes'] ?? [];
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

      transaction.update(commentRef, {'likes': likes});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comentários',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerCommentsLoading();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum comentário ainda.'));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData =
                        comments[index].data() as Map<String, dynamic>;
                    final commentId = comments[index].id;
                    final username = commentData['username'] ?? 'Unknown';
                    final comment = commentData['comment'] ?? '';
                    final timestamp = commentData['created_at'] as Timestamp?;
                    final likes = (commentData['likes'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [];
                    final isLiked =
                        likes.contains(FirebaseAuth.instance.currentUser?.uid);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  commentData['user_photo'] != null &&
                                          commentData['user_photo'] != ''
                                      ? CachedNetworkImageProvider(
                                          commentData['user_photo'])
                                      : null,
                              child: commentData['user_photo'] == null ||
                                      commentData['user_photo'] == ''
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              comment,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Text(
                              timestamp != null
                                  ? _formatTimestamp(timestamp)
                                  : 'Desconhecido',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : null,
                                ),
                                onPressed: () => _likeComment(commentId,
                                    FirebaseAuth.instance.currentUser!.uid),
                              ),
                              Text('${likes.length} curtidas'),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () {
                                  // Campo para responder ao comentário
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final TextEditingController
                                          replyController =
                                          TextEditingController();
                                      return AlertDialog(
                                        title:
                                            const Text('Responder comentário'),
                                        content: TextField(
                                          controller: replyController,
                                          decoration: const InputDecoration(
                                              hintText:
                                                  'Escreva sua resposta...'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              if (replyController
                                                  .text.isNotEmpty) {
                                                _replyToComment(commentId,
                                                    replyController.text);
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            child: const Text('Enviar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text('Responder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          CommentActionBar(
            commentController: _commentController,
            onAddComment: _addComment,
          ),
        ],
      ),
    );
  }

  Future<void> _replyToComment(String commentId, String replyText) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final username = userData['username'] ?? 'Anônimo';
          final userPhoto = userData['profile_picture'] ?? '';

          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .doc(commentId)
              .collection('replies')
              .add({
            'user_id': currentUser.uid,
            'username': username,
            'user_photo': userPhoto,
            'reply': replyText,
            'created_at': Timestamp.now(),
          });
        }
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final Duration difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
