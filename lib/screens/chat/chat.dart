import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social/screens/chat_details/chat_details.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
      });
    });
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
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality if needed
            },
          ),
        ],
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
            final participantsData = chatData['participants'];
            final participants = participantsData is List
                ? List<String>.from(participantsData)
                : <String>[];

            // Verifica se o usuário atual é um dos participantes
            if (!participants.contains(currentUserId)) {
              return false;
            }

            final lastMessage =
                (chatData['last_message'] as String?)?.toLowerCase() ?? '';
            return _searchTerm.isEmpty || lastMessage.contains(_searchTerm);
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

              final lastMessage = chatData['last_message'];
              final lastMessageTime =
                  (chatData['last_message_time'] as Timestamp).toDate();
              final participantsData = chatData['participants'];
              final participants = participantsData is List
                  ? List<String>.from(participantsData)
                  : <String>[];

              final isPinned = chatData.containsKey('is_pinned')
                  ? chatData['is_pinned']
                  : false;

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
                    // Fixar conversa
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chat.id)
                        .update({
                      'is_pinned': !isPinned,
                    });
                    return false; // Não apagar
                  } else if (direction == DismissDirection.endToStart) {
                    // Confirmar a exclusão
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
                    return confirm ?? false; // Retorna true para excluir se confirmado
                  }
                  return false;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    // Apagar conversa
                    FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chat.id)
                        .delete();
                  }
                },
                child: FutureBuilder<DocumentSnapshot>(
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
                          child: const CircularProgressIndicator.adaptive(),
                        ),
                        title: const Text('Carregando...'),
                        subtitle: const Text('Carregando...'),
                      );
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person),
                        ),
                        title: const Text('Unknown User'),
                        subtitle: Text(lastMessage ?? ''),
                      );
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;

                    final userName = userData?['username'] ?? 'Unknown';
                    final userProfilePicture =
                        userData?['profile_picture'] ?? '';

                    final formattedTime =
                        DateFormat('hh:mm a').format(lastMessageTime);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userProfilePicture.isNotEmpty
                            ? NetworkImage(userProfilePicture)
                            : null,
                        child: userProfilePicture.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(userName),
                      subtitle: Text(lastMessage ?? ''),
                      trailing: SizedBox(
                        width: 100, // Ajuste o tamanho conforme necessário
                        child: Row(
                          children: [
                            Text(formattedTime),
                            if (currentUserId != otherParticipantId)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chat.id)
                                    .get(),
                                builder: (context, chatSnapshot) {
                                  if (chatSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container();
                                  }

                                  final chatData = chatSnapshot.data?.data()
                                          as Map<String, dynamic>? ??
                                      {};

                                  final unreadCount =
                                      (chatData['unread_count'] as int?) ?? 0;

                                  return unreadCount > 0
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : Container();
                                },
                              ),
                          ],
                        ),
                      ),
                      onTap: () {
                        if (currentUserId != otherParticipantId) {
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chat.id)
                              .update({
                            'unread_count': 0,
                          });
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              chatId: chat.id,
                              userId: otherParticipantId,
                            ),
                          ),
                       

        );
      },
    );
  },
)
              );
            },
          );
        },
      ),
    );
  }
}
