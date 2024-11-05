import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/post/post.dart';
import 'package:social/screens/story/story.dart';
import 'package:social/screens/story/story_details/story_details.dart';
import 'package:social/screens/profile/user_profile/user_profile.dart';
import 'package:social/widgets/feed/post_tiles.dart';
import 'package:social/widgets/feed/shimmer_post.dart';
import 'package:social/widgets/feed/shimmer_story.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key, required this.currentUserId});

  final String currentUserId;

  void _addPost(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const PostScreen(),
      ),
    );
  }

  void _addStory(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const StoriesScreen(),
      ),
    );
  }

  void _openStory(
      BuildContext context, String userId, String storyId, bool isNew) async {
    if (isNew) {
      // Marcar a história como vista
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .update({
        'viewed_by': FieldValue.arrayUnion([currentUserId])
      });
    }
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      CupertinoPageRoute(
        builder: (context) => StoryDetailScreen(userId: userId),
      ),
    );
  }

  void _openUserProfile(BuildContext context, String userId, String userName) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          username: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addPost(context),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _addStory(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 16.0),
          ),

          // Stories Section
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stories')
                  .where('created_at',
                      isGreaterThanOrEqualTo:
                          DateTime.now().subtract(const Duration(hours: 24)))
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return buildShimmerStory();
                      },
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final stories = snapshot.data!.docs;

                // Agrupar histórias por usuário
                final groupedStories = <String, List<DocumentSnapshot>>{};
                for (var story in stories) {
                  final userId = story['user_id'];
                  if (!groupedStories.containsKey(userId)) {
                    groupedStories[userId] = [];
                  }
                  groupedStories[userId]!.add(story);
                }

                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: groupedStories.keys.length,
                    itemBuilder: (context, index) {
                      final userId = groupedStories.keys.elementAt(index);
                      final userStories = groupedStories[userId]!;

                      final story = userStories.first;
                      final userName = story['username'] ?? 'Unknown';
                      final userPhoto = story['user_photo'] ?? '';

                      // Verifique se o campo 'viewed_by' existe e se contém o ID do usuário
                      final storyData = story.data() as Map<String, dynamic>?;

                      final viewedBy = storyData != null &&
                              storyData.containsKey('viewed_by')
                          ? (storyData['viewed_by'] as List<dynamic>?)
                          : <dynamic>[]; // Valor padrão se o campo não existir

                      final isNew =
                          viewedBy != null && !viewedBy.contains(currentUserId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () =>
                              _openStory(context, userId, story.id, isNew),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isNew
                                            ? Colors.blue
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundImage: userPhoto.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              userPhoto)
                                          : null,
                                      child: userPhoto.isEmpty
                                          ? const Icon(Icons.person, size: 40)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      userName,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Posts Feed
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('created_at', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return buildShimmerPost();
                          },
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                          child: Text(AppLocalizations.of(context)!.noResult));
                    }

                    final posts = snapshot.data!.docs;

                    return Column(
                      children: posts.map((post) {
                        final userId = post['user_id'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return const SizedBox.shrink();
                            }

                            final userData = userSnapshot.data!.data()
                                as Map<String, dynamic>;
                            final userName = userData['username'] ?? 'Unknown';
                            final userProfilePicture =
                                userData['profile_picture'] ?? '';

                            final postData =
                                post.data() as Map<String, dynamic>?;
                            final imageUrl = postData != null &&
                                    postData.containsKey('file_url')
                                ? postData['file_url'] as String?
                                : null;

                            return PostTile(
                              username: userName,
                              userProfilePicture: userProfilePicture,
                              content: post['content'],
                              createdAt: post['created_at'].toDate(),
                              imageUrl: imageUrl,
                              postId: post.id,
                              onProfileTap: () =>
                                  _openUserProfile(context, userId, userName),
                              currentUserId: currentUserId,
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}
