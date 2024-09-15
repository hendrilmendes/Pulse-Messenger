import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social/screens/comments/comments.dart';
import 'package:social/screens/post_details/post_details.dart';
import 'package:social/screens/shared/shared.dart';
import 'package:social/widgets/video/video_player.dart';

class PostTile extends StatefulWidget {
  final String username;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final String postId;
  final String userProfilePicture;
  final VoidCallback onProfileTap;
  final String currentUserId;

  const PostTile({
    required this.username,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    required this.postId,
    required this.userProfilePicture,
    required this.onProfileTap,
    required this.currentUserId,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PostTileState createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>;
      final likes = postData['likes'];

      if (mounted) {
        if (likes is List) {
          final likeList = likes.map((e) => e.toString()).toList();
          setState(() {
            _isLiked = likeList.contains(widget.currentUserId);
          });
        } else {
          setState(() {
            _isLiked = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking if liked: $e");
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;

        final postData = postSnapshot.data() as Map<String, dynamic>;
        final likes = List<String>.from(postData['likes'] ?? []);

        if (_isLiked) {
          likes.remove(widget.currentUserId);
        } else {
          likes.add(widget.currentUserId);

          final notificationsCollection =
              FirebaseFirestore.instance.collection('notifications');
          final existingNotificationsQuery = notificationsCollection
              .where('post_id', isEqualTo: widget.postId)
              .where('from_user_id', isEqualTo: widget.currentUserId)
              .where('is_notified', isEqualTo: false)
              .limit(1)
              .get();

          if ((await existingNotificationsQuery).docs.isEmpty) {
            await notificationsCollection.add({
              'user_id': postData['user_id'],
              'from_user_id': widget.currentUserId,
              'type': 'like',
              'created_at': FieldValue.serverTimestamp(),
              'is_notified': false,
              'post_id': widget.postId,
            });
          }
        }

        transaction.update(postRef, {'likes': likes});
      });

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error toggling like: $e");
      }
    }
  }

  void _onImageTap() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PostDetailsScreen(postId: widget.postId),
      ),
    );
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
          builder: (_, controller) {
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
                        postId: widget.postId,
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
          initialChildSize: 0.9,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
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
                      child: ShareOptionsScreen(postId: widget.postId),
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

  bool _isVideo(String url) {
    // Verifica se a URL contém uma extensão de vídeo comum
    return url.contains(".mp4") || url.contains(".mov") || url.contains(".avi");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.userProfilePicture.isNotEmpty
                        ? CachedNetworkImageProvider(widget.userProfilePicture)
                        : null,
                    radius: 20,
                    child: widget.userProfilePicture.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Text(
                    '${widget.createdAt.day}/${widget.createdAt.month}/${widget.createdAt.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Video ou Imagem do post
          if (widget.imageUrl != null)
            GestureDetector(
              onTap: _onImageTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _isVideo(widget.imageUrl!)
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayerWidget(url: widget.imageUrl!),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                ),
              ),
            ),

          // Post Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.content,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const Divider(),

          // Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox
                          .shrink(); // Handle case where data is not yet available
                    }

                    final postData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final likes = postData['likes'];
                    final postOwnerId =
                        postData['user_id'] ?? ''; // Fetch the post owner's ID

                    int likesCount = 0;
                    if (likes is List) {
                      likesCount = (likes).length;
                    } else if (likes is int) {
                      likesCount = likes;
                    }

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : null,
                          ),
                          onPressed: _toggleLike,
                        ),
                        Text('$likesCount curtidas'),
                        IconButton(
                          icon: const Icon(Icons.comment, size: 20),
                          onPressed: () {
                            _showComments(context,
                                postOwnerId); // Passar o ID do proprietário correto
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () {
                            _showShareOptions(context);
                          },
                        ),
                      ],
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
