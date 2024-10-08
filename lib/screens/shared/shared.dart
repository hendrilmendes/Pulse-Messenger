import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  List<User> _chatUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _fetchChatUsers();
  }

  Future<void> _fetchChatUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get chat user IDs
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      final Set<String> uniqueUserIds = {};

      for (var chat in chatQuery.docs) {
        final participants = chat['participants'] as List<dynamic>;
        for (var participant in participants) {
          if (participant != currentUserId) {
            uniqueUserIds.add(participant);
          }
        }
      }

      // Fetch user data for chat users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uniqueUserIds.toList())
          .get();

      final chatUsers =
          usersSnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

      setState(() {
        _chatUsers = chatUsers;
        _filteredUsers = chatUsers;
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
      _filteredUsers = _chatUsers.where((user) {
        return user.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _sharePost(String recipientId, String chatId) async {
    if (recipientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID do destinatário não pode estar vazio.'),
        ),
      );
      return;
    }

    try {
      // Adiciona o post compartilhado à coleção 'shared_posts'
      await FirebaseFirestore.instance.collection('shared_posts').add({
        'post_id': widget.postId,
        'recipient_id': recipientId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Envia uma mensagem no chat informando que um post foi compartilhado
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'sender_id': _auth.currentUser!.uid,
        'text': 'Um post foi compartilhado.',
        'post_id': widget
            .postId, // Você pode salvar o ID do post para futuras referências
        'timestamp': FieldValue.serverTimestamp(),
        'type':
            'post_share', // Tipo de mensagem para identificar compartilhamento
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
                                    onPressed: () async {
                                      final currentUserId =
                                          _auth.currentUser!.uid;

                                      // Check if a chat exists between current user and recipient
                                      final chatQuery = await FirebaseFirestore
                                          .instance
                                          .collection('chats')
                                          .where('participants',
                                              arrayContains: currentUserId)
                                          .get();

                                      String chatId;

                                      // Check if chat exists
                                      if (chatQuery.docs.isNotEmpty) {
                                        // Chat exists, retrieve its ID
                                        chatId = chatQuery.docs.first.id;
                                      } else {
                                        // Chat does not exist, create a new chat
                                        final newChatDoc =
                                            await FirebaseFirestore.instance
                                                .collection('chats')
                                                .add({
                                          'participants': [
                                            currentUserId,
                                            user.id
                                          ],
                                          'created_at':
                                              FieldValue.serverTimestamp(),
                                        });
                                        chatId = newChatDoc.id;
                                      }

                                      // Now call the _sharePost with both user.id and chatId
                                      await _sharePost(user.id, chatId);
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
