import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/user_profile/user_profile.dart';
import 'package:social/screens/post_details/post_details.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  bool _isSearchingUsers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  _searchQuery = _capitalizeWords(query);
                  _isSearchingUsers = _searchQuery.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Pesquisar...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildPostSearchResults()
          : _isSearchingUsers
              ? _buildUserSearchResults()
              : _buildPostSearchResults(),
    );
  }

  String _capitalizeWords(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildPostSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Nada encontrado.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.data() as Map<String, dynamic>;
            final imageUrl = postData['file_url'] as String?;
            final userId = postData['user_id'];
            final postId = post.id;

            // Busca o nome do usuário no documento do usuário correspondente
            final userRef =
                FirebaseFirestore.instance.collection('users').doc(userId);
            return FutureBuilder<DocumentSnapshot>(
              future: userRef.get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['username'] ?? 'Unknown';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(
                          postId: postId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8.0)),
                                child: Image.network(imageUrl,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover),
                              )
                            : const SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            postData['content'] ?? 'Sem conteúdo',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            userName, // Exibe o nome do usuário
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14.0,
                                color: Colors.blueAccent),
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
    );
  }

  Widget _buildUserSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .startAt([_searchQuery]).endAt(['$_searchQuery\uf8ff']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Não foi encontrado esse usuário.',
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
                      ? NetworkImage(userPhoto)
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
                    MaterialPageRoute(
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
