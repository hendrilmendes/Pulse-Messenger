import 'package:flutter/material.dart';
import 'package:social/screens/chat/user/audio/audio.dart';
import 'package:social/screens/chat/user/video/video.dart';
import 'package:social/widgets/message_input_bar.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {

  final List<Map<String, dynamic>> messages = [
    {
      'text':
          'Sounds good! How about we meet at the coffee shop near our office?',
      'isMe': false,
      'time': '10:25 AM',
    },
    {
      'image': 'https://i.imgur.com/QCNbOAo.jpg',
      'isMe': false,
      'time': '10:30 AM',
    },
    {'text': 'Perfect! See you then.', 'isMe': false, 'time': '10:35 AM'},
    {
      'text': 'Hey Emily, I just came across this interesting article.',
      'isMe': true,
      'time': '10:40 AM',
    },
    {
      'text': '👋 Thanks, I\'ll have a look at it later.',
      'isMe': false,
      'time': '10:45 AM',
    },
    {
      'text': 'No problem, Emily. Let me know what you think!',
      'isMe': true,
      'time': '10:50 AM',
    },
  ];

  Widget _buildMessage(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'];
    final bool hasImage = msg['image'] != null;
    final Radius radius = const Radius.circular(16);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: hasImage ? EdgeInsets.zero : const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.transparent
                  : isMe
                  ? const Color(0xFFF25C54) // coral
                  : const Color(0xFFE5F6F4), // azul acinzentado claro
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: isMe ? radius : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : radius,
              ),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(msg['image'], fit: BoxFit.cover),
                  )
                : Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['time'],
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (isMe)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.done_all, size: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              child: Text('E', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emily Clark', style: TextStyle(fontSize: 16)),
                Text('online', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AudioCallScreen(
                    channelName: '',
                    appId: '',
                    userName: '',
                    userPhotoUrl: '',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const VideoCallScreen(channelName: '', appId: ''),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          const Divider(height: 1),
          MessageInputBar(),
        ],
      ),
    );
  }
}
