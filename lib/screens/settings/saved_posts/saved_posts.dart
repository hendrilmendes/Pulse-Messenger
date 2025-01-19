import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:social/screens/post/post_details/post_details.dart';

class SavedPostsScreen extends StatelessWidget {
  final String userId;

  const SavedPostsScreen({required this.userId, super.key});

  Future<List<String>> _getSavedPosts() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return List<String>.from(userDoc.data()?['saved_posts'] ?? []);
  }

  Future<Widget> _generateVideoThumbnail(String videoUrl) async {
    final thumbnail = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 800,
      quality: 75,
    );

    if (thumbnail != null) {
      return Image.memory(thumbnail, fit: BoxFit.cover);
    } else {
      return const Center(
          child: Icon(Icons.video_library, size: 50, color: Colors.grey));
    }
  }

  void _openPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.savedPosts,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        future: _getSavedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)!.noSavedPosts));
          }

          final savedPosts = snapshot.data!;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.75,
            ),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              final postId = savedPosts[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final postData =
                      postSnapshot.data!.data() as Map<String, dynamic>;
                  final postContent = postData['content'] ?? 'Sem legenda';
                  final userPhoto = postData['user_photo'] ?? '';
                  final mediaUrl = postData['file_url'] ?? '';
                  final mediaType = postData['file_type'] ?? 'text';

                  return GestureDetector(
                    onTap: () {
                      _openPost(context, postId);
                    },
                    child: Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Stack(
                        children: [
                          if (mediaType == 'image' && mediaUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: CachedNetworkImage(
                                imageUrl: mediaUrl,
                                fit: BoxFit.cover,
                                height: double.infinity,
                                width: double.infinity,
                              ),
                            )
                          else if (mediaType == 'video' && mediaUrl.isNotEmpty)
                            FutureBuilder<Widget>(
                              future: _generateVideoThumbnail(mediaUrl),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: SizedBox.expand(
                                    child: snapshot.data ??
                                        const SizedBox.shrink(),
                                  ),
                                );
                              },
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Text(
                                    postContent,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: userPhoto.isNotEmpty
                                  ? CachedNetworkImageProvider(userPhoto)
                                  : null,
                              child: userPhoto.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                postContent,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
