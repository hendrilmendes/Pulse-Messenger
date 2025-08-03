import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social/screens/chat/chat_details/chat_details.dart';
import 'package:social/screens/contacts/contacts.dart';
import 'package:social/screens/group/group.dart';
import 'package:social/services/notification.dart';
import 'package:social/widgets/chat/shimmer_chat.dart';
import 'package:social/widgets/search/search.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchTerm = '';
  final NotificationService _notificationService = NotificationService();
  Map<String, DateTime> lastNotificationTimes = {};
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchTerm = _searchController.text.toLowerCase();
      });
    });
    _updateUserStatus('online');
    _notificationService.init();

    _chatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.modified) {
              final chatData = doc.doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(
                chatData['participants'] ?? [],
              );
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final lastMessageTime =
                  chatData['last_message_time'] is Timestamp
                      ? chatData['last_message_time'].toDate()
                      : DateTime.now();

              if (currentUserId != null &&
                  participants.contains(currentUserId)) {
                final otherParticipantId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );

                if (otherParticipantId.isNotEmpty) {
                  _sendPushNotification(
                    otherParticipantId,
                    chatData['last_message'] ?? '',
                    int.tryParse(doc.doc.id.hashCode.toString()) ?? 0,
                    lastMessageTime,
                  );
                }
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _updateUserStatus('offline');
    _chatsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateUserStatus(String status) async {
    final userId = _auth.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'status': status,
      'last_seen': Timestamp.now(),
    });
  }

  Future<void> _sendPushNotification(
    String otherParticipantId,
    String lastMessage,
    int index,
    DateTime messageTime,
  ) async {
    final userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(otherParticipantId)
            .get();

    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      final userName = userData?['username'] ?? 'Usuário';
      final userPhotoUrl = userData?['profile_picture'];

      if (userData != null) {
        final lastNotificationTime = await _getLastNotificationTime(
          otherParticipantId,
        );
        if (messageTime.isAfter(lastNotificationTime)) {
          await _notificationService.showNotification(
            title: 'Nova mensagem de $userName',
            body:
                lastMessage.isNotEmpty
                    ? lastMessage
                    : 'Você tem uma nova mensagem.',
            notificationId: index,
            userPhotoUrl: userPhotoUrl,
          );

          await _updateLastNotificationTime(otherParticipantId, messageTime);
        } else {
          if (kDebugMode) {
            print('A notificação já foi enviada para esta mensagem.');
          }
        }
      }
    }
  }

  Future<DateTime> _getLastNotificationTime(String otherParticipantId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('notification_times')
            .doc(otherParticipantId)
            .get();

    if (doc.exists) {
      final data = doc.data();
      return (data?['last_notification_time'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<void> _updateLastNotificationTime(
    String otherParticipantId,
    DateTime messageTime,
  ) async {
    await FirebaseFirestore.instance
        .collection('notification_times')
        .doc(otherParticipantId)
        .set({'last_notification_time': Timestamp.fromDate(messageTime)});
  }

  Future<bool> _checkIfBlocked(String otherParticipantId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    final userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      final blockedUsers = List<String>.from(userData?['blocked_users'] ?? []);
      return blockedUsers.contains(otherParticipantId);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma conversa.'));
          }

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) {
            return const Center(child: Text('Usuário não logado'));
          }

          final chats =
              snapshot.data!.docs.where((chat) {
                final chatData = chat.data() as Map<String, dynamic>;
                final participants = List<String>.from(
                  chatData['participants'] ?? [],
                );
                return participants.contains(currentUserId);
              }).toList();

          // Filtrar chats com base no termo de pesquisa
          final filteredChats =
              chats.where((chat) {
                final chatData = chat.data() as Map<String, dynamic>;
                final lastMessage = chatData['last_message'] ?? '';
                final groupName =
                    chatData['is_group'] == true
                        ? chatData['group_name'] ?? ''
                        : '';
                final otherParticipantId =
                    (List<String>.from(chatData['participants'] ?? [])
                      ..remove(currentUserId)).firstOrNull ??
                    '';

                return lastMessage.toLowerCase().contains(searchTerm) ||
                    groupName.toLowerCase().contains(searchTerm) ||
                    otherParticipantId.isNotEmpty &&
                        otherParticipantId.toLowerCase().contains(searchTerm);
              }).toList();

          return ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              final chatData = chat.data() as Map<String, dynamic>?;

              // Verificação do chatData e participantes válidos
              if (chatData == null) {
                return const ListTile(
                  leading: ShimmerChatAvatar(radius: 24),
                  title: Text('Erro'),
                  subtitle: Text('Dados do chat não encontrados'),
                );
              }

              final lastMessage = chatData['last_message'] ?? '';
              final lastMessageTimeRaw = chatData['last_message_time'];
              final lastMessageTime =
                  lastMessageTimeRaw is Timestamp
                      ? lastMessageTimeRaw.toDate()
                      : DateTime.now();

              final participants = List<String>.from(
                chatData['participants'] ?? [],
              );
              final isPinned = chatData['is_pinned'] ?? false;
              final isGroup = chatData['is_group'] ?? false;

              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId == null) {
                return const ListTile(
                  leading: ShimmerChatAvatar(radius: 24),
                  title: Text('Erro'),
                  subtitle: Text('Usuário não logado'),
                );
              }

              final otherParticipantId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherParticipantId.isEmpty ||
                  otherParticipantId == currentUserId) {
                return const SizedBox();
              }

              if (otherParticipantId.isEmpty) {
                return const ListTile(
                  leading: ShimmerChatAvatar(radius: 24),
                  title: Text('Erro'),
                  subtitle: Text('Nenhum outro participante encontrado'),
                );
              }

              // Formatando data e hora
              final formattedTime = DateFormat('HH:mm').format(lastMessageTime);

              return Dismissible(
                key: ValueKey(chat.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Colors.blue,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.push_pin, color: Colors.white),
                    ),
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chat.id)
                        .update({'is_pinned': !isPinned});
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    final bool? confirm = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Excluir conversa'),
                          content: const Text(
                            'Tem certeza de que deseja excluir esta conversa?',
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: const Text('Excluir'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        );
                      },
                    );
                    return confirm ?? false;
                  }
                  return false;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chat.id)
                        .delete();
                  }
                },
                child: FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection(isGroup ? 'chats' : 'users')
                          .doc(isGroup ? chat.id : otherParticipantId)
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: ShimmerChatAvatar(radius: 24),
                        title: Text('Carregando...'),
                        subtitle: Text('Carregando...'),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return ListTile(
                        leading: const ShimmerChatAvatar(radius: 24),
                        title: const Text('Usuário/Grupo Desconhecido'),
                        subtitle: Text(lastMessage),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final title =
                        data?[isGroup ? 'group_name' : 'username'] ??
                        'Desconhecido';
                    final profilePicture =
                        data?[isGroup ? 'group_image' : 'profile_picture'] ??
                        '';

                    // Obtenha o unread_count do chat
                    final unreadCount =
                        chatData['unread_count'] is Map
                            ? chatData['unread_count'][currentUserId] ?? 0
                            : chatData['unread_count'] ?? 0;

                    return FutureBuilder<bool>(
                      future: _checkIfBlocked(otherParticipantId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            leading: ShimmerChatAvatar(radius: 24),
                            title: Text('Carregando...'),
                            subtitle: Text('Carregando...'),
                          );
                        }

                        final isBlocked = snapshot.data ?? false;

                        if (isBlocked && !isGroup) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(Icons.block, color: Colors.red),
                            ),
                            title: const Text('Usuário Bloqueado'),
                            subtitle: const Text(
                              'Você não pode ver as mensagens desse usuário.',
                            ),
                            trailing: Text(formattedTime),
                          );
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                profilePicture.isNotEmpty
                                    ? CachedNetworkImageProvider(profilePicture)
                                    : null,
                            child:
                                profilePicture.isEmpty
                                    ? Icon(
                                      isGroup ? Icons.group : Icons.person,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          title: Text(title),
                          subtitle: Text(
                            lastMessage.length > 30
                                ? '${lastMessage.substring(0, 30)}...'
                                : lastMessage,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(formattedTime),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chat.id)
                                .update({'unread_count.$currentUserId': 0});

                            lastNotificationTimes[otherParticipantId] =
                                DateTime.now();

                            Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (context) =>
                                        isGroup
                                            ? GroupChatScreen(
                                              chatId: chat.id,
                                              userId: currentUserId,
                                              isGroup: isGroup,
                                            )
                                            : ChatDetailScreen(
                                              chatId: chat.id,
                                              userId: otherParticipantId,
                                              isGroup: isGroup,
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
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const ContactsScreen()),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}
