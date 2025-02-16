import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social/screens/chat/chat_details/chat_details.dart';
import 'package:social/screens/group/group_create/grupo_create.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<String> selectedContacts = [];
  bool isSelecting = false;
  List<String> chatUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  Future<void> _loadChatUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final chatQuery =
        await FirebaseFirestore.instance
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

    setState(() {
      chatUserIds = uniqueUserIds.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contatos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed:
                selectedContacts.isEmpty
                    ? null
                    : () async {
                      await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (context) => CreateGroupScreen(
                                selectedContacts: selectedContacts,
                              ),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {
                        selectedContacts.clear();
                        isSelecting = false;
                      });
                    },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where(
                  FieldPath.documentId,
                  whereIn:
                      chatUserIds.isNotEmpty ? chatUserIds : ['placeholder'],
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || chatUserIds.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final username = userData['username'] ?? 'Usuário Desconhecido';
              final userId = user.id;
              final phone = userData['phone'] ?? '';
              final profilePicture = userData['profile_picture'] ?? '';

              final isSelected = selectedContacts.contains(userId);
              final showCheckbox = isSelecting;

              return GestureDetector(
                onLongPress: () {
                  setState(() {
                    isSelecting = true;
                  });
                },
                onTap: () async {
                  if (isSelecting) {
                    setState(() {
                      if (isSelected) {
                        selectedContacts.remove(userId);
                      } else {
                        selectedContacts.add(userId);
                      }
                    });
                  } else {
                    final chatId = await _getOrCreateChatId(userId);
                    if (!mounted) return;
                    await Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      CupertinoPageRoute(
                        builder:
                            (context) => ChatDetailScreen(
                              chatId: chatId,
                              isGroup: false,
                              userId: userId,
                            ),
                      ),
                    );
                  }
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        profilePicture.isNotEmpty
                            ? CachedNetworkImageProvider(profilePicture)
                            : null,
                    child:
                        profilePicture.isEmpty
                            ? Text(username[0].toUpperCase())
                            : null,
                  ),
                  title: Text(username),
                  subtitle: phone.isNotEmpty ? Text(phone) : null,
                  trailing:
                      showCheckbox
                          ? Checkbox(
                            value: isSelected,
                            onChanged: (isSelected) {
                              setState(() {
                                if (isSelected == true) {
                                  selectedContacts.add(userId);
                                } else {
                                  selectedContacts.remove(userId);
                                }
                              });
                            },
                          )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String> _getOrCreateChatId(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return '';

    final chatQuery =
        await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();

    for (var chat in chatQuery.docs) {
      final participants = chat['participants'] as List<dynamic>;
      if (participants.length == 2 && participants.contains(userId)) {
        return chat.id;
      }
    }

    final chatId = FirebaseFirestore.instance.collection('chats').doc().id;

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'group_name': '',
      'is_group': false,
      'participants': [currentUserId, userId],
      'admin': currentUserId,
      'last_message': '',
      'last_message_time': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    return chatId;
  }
}
