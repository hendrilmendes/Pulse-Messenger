import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/chat_details/chat_details.dart';
import 'package:social/screens/post_details/post_details.dart';

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

    setState(() {
      postCount = postSnapshot.size;
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

    if (chatQuery.exists) {
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatIdString,
            userId: userId,
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
      });

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatIdString,
            userId: userId,
          ),
        ),
      );
    }
  }

  void _openPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
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
        title: Text(widget.username),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                          ? NetworkImage(userProfilePicture)
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
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('user_id', isEqualTo: widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                          final postImage = postData?['image_url'] ?? '';
                          return GestureDetector(
                            onTap: () => _openPost(context, post.id),
                            child: Container(
                              decoration: BoxDecoration(
                                image: postImage.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(postImage),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
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
