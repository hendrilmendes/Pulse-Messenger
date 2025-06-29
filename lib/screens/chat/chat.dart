import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:social/models/chat_model.dart';
import 'package:social/screens/chat/call/call.dart';
import 'package:social/screens/chat/group/group.dart';
import 'package:social/screens/chat/user/user.dart';
import 'package:social/services/chat/chat.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _showFab = true;
  final ScrollController _scrollController = ScrollController();
  late Future<List<Conversation>> _conversationsFuture;

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showFab) setState(() => _showFab = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showFab) setState(() => _showFab = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _conversationsFuture = ChatService().getConversations();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Text(
            'Conversas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      // Implementar busca filtrada se quiser
                    },
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Pessoais'),
                    Tab(text: 'Grupos'),
                    Tab(text: 'Chamadas'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Aba de conversas pessoais - aqui consumimos da API
            FutureBuilder<List<Conversation>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final conversations = snapshot.data ?? [];
                if (conversations.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma conversa encontrada.'),
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final convo = conversations[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserChatScreen(),
                          ),
                        );
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Apagar'),
                                  onTap: () {
                                    // Apagar conversa (implementar)
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.archive),
                                  title: const Text('Arquivar'),
                                  onTap: () {
                                    // Arquivar conversa (implementar)
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.notifications_off),
                                  title: const Text('Silenciar'),
                                  onTap: () {
                                    // Silenciar conversa (implementar)
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(convo.avatarUrl),
                        radius: 28,
                      ),
                      title: Text(
                        convo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        convo.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Text(
                        convo.updatedAt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Aba de grupos - aqui você pode implementar fetch parecido
            ListView.separated(
              itemCount: 1,
              separatorBuilder: (_, _) => const Divider(height: 0),
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GroupChatScreen(),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/300?img=6',
                    ),
                    radius: 28,
                  ),
                  title: const Text(
                    'Grupo Flutter Devs',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Novo plugin lançado!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: const Text(
                    'Ontem',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),

            // Aba de chamadas
            ListView.separated(
              itemCount: 2,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final callsConversations = [
                  {
                    'name': 'Ana Clara',
                    'callType': 'video',
                    'time': 'Hoje, 10:24',
                    'avatar': 'https://i.pravatar.cc/300?img=5',
                    'status': 'received',
                  },
                  {
                    'name': 'Lucas Almeida',
                    'callType': 'audio',
                    'time': 'Ontem, 18:10',
                    'avatar': 'https://i.imgur.com/BoN9kdC.png',
                    'status': 'missed',
                  },
                ];
                final call = callsConversations[index];
                IconData callIcon = call['callType'] == 'video'
                    ? Icons.videocam
                    : Icons.call;
                Color iconColor;
                switch (call['status']) {
                  case 'missed':
                    iconColor = Colors.red;
                    break;
                  case 'outgoing':
                    iconColor = Colors.green;
                    break;
                  default:
                    iconColor = Colors.blue;
                }
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          isVideoCall: call['callType'] == 'video',
                          callerName: call['name']!,
                          callerAvatarUrl: call['avatar']!,
                          callStatus: call['status'] == 'missed'
                              ? 'Chamada perdida'
                              : call['status'] == 'outgoing'
                              ? 'Chamada realizada'
                              : 'Chamada recebida',
                          callDuration: null,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(call['avatar']!),
                    radius: 28,
                  ),
                  title: Text(
                    call['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        call['status'] == 'missed'
                            ? Icons.call_missed
                            : call['status'] == 'outgoing'
                            ? Icons.call_made
                            : Icons.call_received,
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        call['time']!,
                        style: TextStyle(fontSize: 13, color: iconColor),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    callIcon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        ),

        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          offset: _showFab ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showFab ? 1 : 0,
            child: FloatingActionButton(
              onPressed: () {
                // Abrir nova conversa
              },
              child: const Icon(
                CupertinoIcons.chat_bubble_fill,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
