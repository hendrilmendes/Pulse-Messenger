import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/screens/post/post_details/post_details.dart';
import 'package:social/screens/profile/user_profile/user_profile.dart';
import 'package:social/services/notification.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('user_id', isEqualTo: currentUser!.uid)
        .where('is_notified', isNotEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final notification = doc.doc.data() as Map<String, dynamic>;
          final type = notification['type'];
          final fromUserId = notification['from_user_id'];
          final notificationId = DateTime.now().millisecondsSinceEpoch;

          FirebaseFirestore.instance
              .collection('users')
              .doc(fromUserId)
              .get()
              .then((userSnapshot) {
            final userData = userSnapshot.data() as Map<String, dynamic>;
            final fromUser = userData['username'] ?? 'Unknown';
            final userPhotoUrl = userData['profile_picture'];
            final notificationText = _buildNotificationText(type, fromUser);

            _notificationService.showNotification(
              title: 'Pulse',
              body: notificationText,
              notificationId: notificationId,
              userPhotoUrl: userPhotoUrl,
            );

            FirebaseFirestore.instance
                .collection('notifications')
                .doc(doc.doc.id)
                .update({'is_notified': true});
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para ver suas atividades.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Atividades',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_id', isEqualTo: currentUser!.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sem novas atividades.'));
          }

          final notifications = snapshot.data!.docs;

          final Map<String, List<Map<String, dynamic>>> groupedNotifications =
              {};
          for (var doc in notifications) {
            final notification = doc.data() as Map<String, dynamic>;
            final createdAt = notification['created_at'] as Timestamp;
            final formattedDate = _formatDate(createdAt.toDate());

            if (groupedNotifications[formattedDate] == null) {
              groupedNotifications[formattedDate] = [];
            }
            groupedNotifications[formattedDate]!.add(notification);
          }

          return ListView(
            children: groupedNotifications.entries.map((entry) {
              final date = entry.key;
              final notifications = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  ...notifications.map((notification) {
                    final type = notification['type'];
                    final fromUserId = notification['from_user_id'];
                    final createdAt = notification['created_at'] as Timestamp;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(fromUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return _buildShimmer();
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final fromUser = userData['username'] ?? 'Unknown';
                        final profilePictureUrl =
                            userData['profile_picture'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profilePictureUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profilePictureUrl)
                                : null,
                            child: profilePictureUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(_buildNotificationText(type, fromUser)),
                          subtitle: Text(_formatTimestamp(createdAt)),
                          trailing: _getNotificationIcon(type),
                          onTap: () async {
                            if (type == 'follow') {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    userId: fromUserId,
                                    username: fromUser,
                                  ),
                                ),
                              );
                            } else if (type == 'like' || type == 'comment') {
                              final postId = notification['post_id'];
                              if (postId != null) {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        PostDetailsScreen(postId: postId),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  })
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _buildNotificationText(String type, String fromUser) {
    switch (type) {
      case 'like':
        return '$fromUser curtiu sua postagem';
      case 'comment':
        return '$fromUser comentou em sua postagem';
      case 'follow':
        return '$fromUser começou a seguir você';
      default:
        return 'Você tem uma nova notificação';
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.grey),
        title: Container(height: 10, color: Colors.grey),
        subtitle: Container(height: 10, color: Colors.grey),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return const Icon(Icons.favorite, color: Colors.red);
      case 'comment':
        return const Icon(Icons.comment, color: Colors.blue);
      case 'follow':
        return const Icon(Icons.person_add, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutos atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} horas atrás';
    } else {
      return '${difference.inDays} dias atrás';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
