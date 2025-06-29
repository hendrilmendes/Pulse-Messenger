import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:social/widgets/message_input_bar.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> messages = [
      {
        'sender': 'Alice',
        'text': 'Olá, pessoal! Alguém já usou o Flutter 3.32?',
        'avatar': 'https://randomuser.me/api/portraits/women/1.jpg',
      },
      {
        'sender': 'Bob',
        'text': 'Oi Alice! Sim, estou testando os novos recursos.',
        'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
      {
        'sender': 'Você',
        'text': 'Eu também! O suporte multiplataforma está incrível.',
        'avatar': 'https://randomuser.me/api/portraits/men/3.jpg',
      },
      {
        'sender': 'Carol',
        'text': 'Vocês já tentaram o Flutter Web?',
        'avatar': 'https://randomuser.me/api/portraits/women/4.jpg',
      },
      {
        'sender': 'Bob',
        'text': 'Ainda não, Carol. É estável?',
        'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
      {
        'sender': 'Você',
        'text': 'Funciona bem para projetos pequenos!',
        'avatar': 'https://randomuser.me/api/portraits/men/3.jpg',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/img/logo.png'),
              radius: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Grupo do Flutter',
                    overflow: TextOverflow.visible,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '250 membros',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.call)),
          IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: const Text('Informações do grupo'),
              ),
              PopupMenuItem(
                value: 'mute',
                child: const Text('Silenciar notificações'),
              ),
              PopupMenuItem(value: 'leave', child: const Text('Sair do grupo')),
            ],
            onSelected: (value) {
              // Handle menu selection
              if (value == 'info') {
                // Navigate to group info screen
              } else if (value == 'mute') {
                // Mute notifications
              } else if (value == 'leave') {
                // Leave the group
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Center(
              child: Text(
                'Hoje',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final isMe = message['sender'] == 'Você';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe)
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(
                            message['avatar']!,
                          ),
                        ),
                      if (!isMe) const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFE1FFC7)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message['sender']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.teal,
                                  ),
                                ),
                              if (!isMe) const SizedBox(height: 2),
                              Text(
                                message['text']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isMe) const SizedBox(width: 8),
                      if (isMe)
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(
                            message['avatar']!,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const _MessageInput(),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  const _MessageInput();

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  @override
  Widget build(BuildContext context) {
    return MessageInputBar();
  }
}
