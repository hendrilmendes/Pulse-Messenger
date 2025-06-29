import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'type': 'like',
        'user': 'Alice',
        'message': 'curtiu sua foto.',
        'time': '2h',
        'image': 'https://via.placeholder.com/150',
      },
      {
        'type': 'comment',
        'user': 'Bob',
        'message': 'comentou: "Incrível!"',
        'time': '3h',
        'image': 'https://via.placeholder.com/150',
      },
      {
        'type': 'follow',
        'user': 'Charlie',
        'message': 'começou a seguir você.',
        'time': '5h',
        'image': 'https://via.placeholder.com/150',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(notification['image']!),
            ),
            title: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: notification['user'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' ${notification['message']}'),
                ],
              ),
            ),
            subtitle: Text(notification['time']!),
            trailing: notification['type'] == 'follow'
                ? ElevatedButton(
                    onPressed: () {},
                    child: const Text('Seguir'),
                  )
                : null,
          );
        },
      ),
    );
  }
}
