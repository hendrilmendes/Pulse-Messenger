import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social/screens/profile/user_profile/user_profile.dart';
import 'package:social/screens/post/post_details/post_details.dart';
import 'package:social/widgets/search/search.dart';
import 'package:social/widgets/search/shimmer_search.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearchingUsers = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      _isSearchingUsers.value = query.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isSearchingUsers.dispose();
    super.dispose();
  }

  Future<String?> _generateVideoThumbnail(String videoUrl) async {
    try {
      final filePath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 100,
      );
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar miniatura do vídeo: $e');
      }
      return null;
    }
  }

  bool _isVideo(String url) {
    return url.contains(".mp4") || url.contains(".mov") || url.contains(".avi");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.search,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              SearchBarWidget(
                searchQuery: _searchController.text,
                onSearchChanged: (query) {
                  _searchController.text = query;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isSearchingUsers,
        builder: (context, isSearching, child) {
          if (_searchController.text.isEmpty) {
            return _buildPostSearchResults();
          }
          return isSearching
              ? _buildUserSearchResults()
              : _buildPostSearchResults();
        },
      ),
    );
  }

  Widget _buildPostSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return const ShimmerSearchWidget(
                height: 100,
                width: 100,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              );
            },
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noResult,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        // Filtra os posts que possuem um 'file_url' válido
        final postsWithMedia = snapshot.data!.docs.where((post) {
          final postData = post.data() as Map<String, dynamic>?;
          final postImage = postData?['file_url'] ?? '';
          return postImage.isNotEmpty;
        }).toList();

        if (postsWithMedia.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noMedia,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          future: _generateVideoThumbnail(postImage),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator.adaptive());
                            }

                            final thumbnailPath = snapshot.data;
                            return Container(
                              decoration: BoxDecoration(
                                image: thumbnailPath != null
                                    ? DecorationImage(
                                        image: FileImage(File(thumbnailPath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(postImage),
                              fit: BoxFit.cover,
                            ),
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                  if (isVideo)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(),
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
    );
  }

  Widget _buildUserSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .startAt([_searchController.text]).endAt(
              ['${_searchController.text}\uf8ff']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noUser,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            final userName = userData['username'] ?? 'Unknown';
            final userPhoto = userData['profile_picture'] as String?;
            final userId = user.id;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8.0),
                leading: CircleAvatar(
                  backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(userPhoto)
                      : null,
                  child: userPhoto == null || userPhoto.isEmpty
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                title: Text(userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.0)),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: userId,
                        username: userName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
