import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social/widgets/search/search.dart';
import 'package:social/widgets/share/shimmer_share.dart';

class ShareOptionsScreen extends StatefulWidget {
  final String postId;

  const ShareOptionsScreen({required this.postId, super.key});

  @override
  State<ShareOptionsScreen> createState() => _ShareOptionsScreenState();
}

class _ShareOptionsScreenState extends State<ShareOptionsScreen> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users =
          usersSnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erro ao buscar usuários: $e';
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _sharePost(String recipientId) async {
    if (recipientId.isEmpty) {
      // Mostrar mensagem de erro se o recipientId estiver vazio
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ID do destinatário não pode estar vazio.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('shared_posts').add({
        'post_id': widget.postId,
        'recipient_id': recipientId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('Post shared successfully!');
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing post: $e');
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compartilhar com...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: ShimmerShareLoading())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    SearchBarWidget(
                      searchQuery: _searchController.text,
                      onSearchChanged: (query) {
                        setState(() {
                          _searchController.text = query;
                        });
                      },
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? const Center(
                              child: Text('Nenhum usuário encontrado'),
                            )
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                        user.profilePicture),
                                  ),
                                  title: Text(user.username),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () {
                                      _sharePost(user.id);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class User {
  final String id;
  final String username;
  final String profilePicture;

  User({
    required this.id,
    required this.username,
    required this.profilePicture,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      username: data['username'] ?? '',
      profilePicture: data['profile_picture'] ?? '',
    );
  }
}
