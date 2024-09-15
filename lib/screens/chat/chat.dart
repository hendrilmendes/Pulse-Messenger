import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social/screens/chat_details/chat_details.dart';
import 'package:social/screens/contacts/contacts.dart';
import 'package:social/screens/group/group.dart';
import 'package:social/services/notification.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchTerm = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendPushNotification(String otherParticipantId,
      String lastMessage, int index, DateTime messageTime) async {
    final currentTime = DateTime.now();
    final lastNotificationTime = lastNotificationTimes[otherParticipantId] ??
        DateTime.fromMillisecondsSinceEpoch(0);

    // Obtenha o nome do usuário do banco de dados
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherParticipantId)
        .get();

    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      final userName = userData?['username'] ?? 'Usuário';

      // Check if the message time is newer than the last notification time
      if (messageTime.isAfter(lastNotificationTime)) {
        // Send the push notification
        _notificationService.showNotification(
          title: 'Nova mensagem de $userName',
          body: lastMessage.isNotEmpty
              ? lastMessage
              : 'Você tem uma nova mensagem.',
          notificationId: index,
        );

        // Update the last notification time
        lastNotificationTimes[otherParticipantId] = currentTime;
      } else {
        if (kDebugMode) {
          print('A notificação já foi enviada para esta mensagem.');
        }
      }
    }
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
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const ContactsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SearchBarWidget(
            searchQuery: _searchController.text,
            onSearchChanged: (query) {
            },
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma conversa.'));
          }

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) {
            return const Center(child: Text('Usuário não logado'));
          }

          final chats = snapshot.data!.docs.where((chat) {
            final chatData = chat.data() as Map<String, dynamic>;
            final participants =
                List<String>.from(chatData['participants'] ?? []);
            return participants.contains(currentUserId);
          }).toList();

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatData = chat.data() as Map<String, dynamic>?;

              if (chatData == null) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                  title: const Text('Erro'),
                  subtitle: const Text('Dados do chat não encontrados'),
                );
              }

              final lastMessage = chatData['last_message'] ?? '';
              final lastMessageTimeRaw = chatData['last_message_time'];
              final lastMessageTime = lastMessageTimeRaw is Timestamp
                  ? lastMessageTimeRaw.toDate()
                  : DateTime
                      .now(); // Defina um valor padrão ou trate o erro conforme necessário

              final participants =
                  List<String>.from(chatData['participants'] ?? []);
              final isPinned = chatData['is_pinned'] ?? false;
              final isGroup = chatData['is_group'] ?? false;

              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (currentUserId == null) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                  title: const Text('Erro'),
                  subtitle: const Text('Usuário não logado'),
                );
              }

              final otherParticipantId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherParticipantId.isEmpty) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                  title: const Text('Erro'),
                  subtitle: const Text('Nenhum outro participante encontrado'),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (lastMessageTimeRaw != null) {
                  _sendPushNotification(
                      otherParticipantId, lastMessage, index, lastMessageTime);
                }
              });

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
                              'Tem certeza de que deseja excluir esta conversa?'),
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
                child: isGroup
                    ? FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chat.id)
                            .get(),
                        builder: (context, groupSnapshot) {
                          if (groupSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child:
                                    const CircularProgressIndicator.adaptive(),
                              ),
                              title: const Text('Carregando...'),
                              subtitle: const Text('Carregando...'),
                            );
                          }

                          if (!groupSnapshot.hasData ||
                              !groupSnapshot.data!.exists) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.group),
                              ),
                              title: const Text('Grupo Desconhecido'),
                              subtitle: Text(lastMessage),
                            );
                          }

                          final groupData = groupSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          final groupName =
                              groupData?['group_name'] ?? 'Grupo Desconhecido';
                          final groupProfilePicture =
                              groupData?['group_photo_url'] ?? '';

                          final formattedTime =
                              DateFormat('hh:mm a').format(lastMessageTime);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: groupProfilePicture.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      groupProfilePicture)
                                  : null,
                              child: groupProfilePicture.isEmpty
                                  ? const Icon(Icons.group)
                                  : null,
                            ),
                            title: Text(groupName),
                            subtitle: Text(lastMessage),
                            trailing: SizedBox(
                              width: 120, // Ajuste conforme necessário
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      formattedTime,
                                      overflow: TextOverflow
                                          .ellipsis, // Adiciona elipses se o texto for muito longo
                                    ),
                                  ),
                                  if (currentUserId != otherParticipantId)
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chat.id)
                                          .get(),
                                      builder: (context, chatSnapshot) {
                                        if (chatSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Container(); // Retorne um widget vazio enquanto carrega
                                        }

                                        final chatData =
                                            chatSnapshot.data?.data()
                                                    as Map<String, dynamic>? ??
                                                {};
                                        final unreadCountRaw =
                                            chatData['unread_count'];

                                        int unreadCount = 0;
                                        if (unreadCountRaw
                                            is Map<String, dynamic>) {
                                          unreadCount =
                                              (unreadCountRaw[currentUserId]
                                                      as int?) ??
                                                  0;
                                        } else if (unreadCountRaw is int) {
                                          unreadCount = unreadCountRaw;
                                        }

                                        return unreadCount > 0
                                            ? Container(
                                                margin: const EdgeInsets.only(
                                                    left: 8),
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    unreadCount.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container();
                                      },
                                    ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              final isGroup = chatData['is_group'] ?? false;

                              if (currentUserId != otherParticipantId) {
                                await FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chat.id)
                                    .update({
                                  'unread_count':
                                      FieldValue.arrayRemove([currentUserId]),
                                });
                              }

                              Navigator.push(
                                // ignore: use_build_context_synchronously
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => isGroup
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
                      )
                    : FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherParticipantId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child:
                                    const CircularProgressIndicator.adaptive(),
                              ),
                              title: const Text('Carregando...'),
                              subtitle: const Text('Carregando...'),
                            );
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person),
                              ),
                              title: const Text('Usuário Desconhecido'),
                              subtitle: Text(lastMessage),
                            );
                          }

                          final userData = userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          final userName =
                              userData?['username'] ?? 'Desconhecido';
                          final userProfilePicture =
                              userData?['profile_picture'] ?? '';

                          final formattedTime =
                              DateFormat('hh:mm a').format(lastMessageTime);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userProfilePicture.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      userProfilePicture)
                                  : null,
                              child: userProfilePicture.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(userName),
                            subtitle: Text(lastMessage),
                            trailing: SizedBox(
                              width: 120, // Ajuste conforme necessário
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      formattedTime,
                                      overflow: TextOverflow
                                          .ellipsis, // Adiciona elipses se o texto for muito longo
                                    ),
                                  ),
                                  if (currentUserId != otherParticipantId)
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chat.id)
                                          .get(),
                                      builder: (context, chatSnapshot) {
                                        if (chatSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Container(); // Retorne um widget vazio enquanto carrega
                                        }

                                        final chatData =
                                            chatSnapshot.data?.data()
                                                    as Map<String, dynamic>? ??
                                                {};
                                        final unreadCountRaw =
                                            chatData['unread_count'];

                                        int unreadCount = 0;
                                        if (unreadCountRaw
                                            is Map<String, dynamic>) {
                                          unreadCount =
                                              (unreadCountRaw[currentUserId]
                                                      as int?) ??
                                                  0;
                                        } else if (unreadCountRaw is int) {
                                          unreadCount = unreadCountRaw;
                                        }

                                        return unreadCount > 0
                                            ? Container(
                                                margin: const EdgeInsets.only(
                                                    left: 8),
                                                padding:
                                                    const EdgeInsets.all(5),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    unreadCount.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container();
                                      },
                                    ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              final isGroup = chatData['is_group'] ?? false;

                              if (currentUserId != otherParticipantId) {
                                await FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chat.id)
                                    .update({
                                  'unread_count':
                                      FieldValue.arrayRemove([currentUserId]),
                                });
                              }

                              Navigator.push(
                                // ignore: use_build_context_synchronously
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => isGroup
                                      ? GroupChatScreen(
                                          chatId: chat.id,
                                          userId: otherParticipantId,
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
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
