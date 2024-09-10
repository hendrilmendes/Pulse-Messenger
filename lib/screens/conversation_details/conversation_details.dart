import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ConversationDetailsScreen extends StatelessWidget {
  final String userId;

  const ConversationDetailsScreen({super.key, required this.userId});

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchMedia() async {
    QuerySnapshot mediaDocs = await FirebaseFirestore.instance
        .collection('media')
        .where('userId', isEqualTo: userId)
        .get();
    return mediaDocs.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Desconhecido';
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Conversa'),
      ),
      body: FutureBuilder(
        future: Future.wait([_fetchUserData(), _fetchMedia()]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          Map<String, dynamic> userData = snapshot.data![0];
          List<Map<String, dynamic>> mediaList = snapshot.data![1];

          // Separate media into types
          List<Map<String, dynamic>> images =
              mediaList.where((media) => media['type'] == 'image').toList();
          List<Map<String, dynamic>> videos =
              mediaList.where((media) => media['type'] == 'video').toList();
          List<Map<String, dynamic>> music =
              mediaList.where((media) => media['type'] == 'music').toList();
          List<Map<String, dynamic>> documents =
              mediaList.where((media) => media['type'] == 'document').toList();
          List<Map<String, dynamic>> calls =
              mediaList.where((media) => media['type'] == 'call').toList();

          // Check online status
          bool isOnline = userData['isOnline'] ?? false;

          // Determine if there's any media or calls
          bool hasMediaOrCalls = images.isNotEmpty ||
              videos.isNotEmpty ||
              music.isNotEmpty ||
              documents.isNotEmpty ||
              calls.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile section
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          userData['profile_picture'] ??
                              'https://example.com/default-pic.jpg'),
                      radius: 30,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['username'] ?? 'User Name',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOnline
                              ? 'Online'
                              : 'Última vez visto: ${_formatTimestamp(userData['last_seen'])}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Buttons aligned side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Add your block functionality here
                        },
                        child: const Text('Bloquear Usuário'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Add your mute functionality here
                        },
                        child: const Text('Desativar Notificações'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Display media or calls
                if (hasMediaOrCalls) ...[
                  // Display images
                  if (images.isNotEmpty) ...[
                    const Text('Imagens',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          var media = images[index];
                          return ListTile(
                            leading: const Icon(Icons.image),
                            title: Text(media['title'] ?? 'Image ${index + 1}'),
                            onTap: () {
                              // Handle media tap
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  // Display videos
                  if (videos.isNotEmpty) ...[
                    const Text('Vídeos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          var media = videos[index];
                          return ListTile(
                            leading: const Icon(Icons.video_call),
                            title: Text(media['title'] ?? 'Video ${index + 1}'),
                            onTap: () {
                              // Handle media tap
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  // Display music
                  if (music.isNotEmpty) ...[
                    const Text('Músicas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: music.length,
                        itemBuilder: (context, index) {
                          var media = music[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(media['title'] ?? 'Music ${index + 1}'),
                            onTap: () {
                              // Handle media tap
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  // Display documents
                  if (documents.isNotEmpty) ...[
                    const Text('Documentos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          var media = documents[index];
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title:
                                Text(media['title'] ?? 'Document ${index + 1}'),
                            onTap: () {
                              // Handle media tap
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  // Display calls
                  if (calls.isNotEmpty) ...[
                    const Text('Chamadas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: calls.length,
                        itemBuilder: (context, index) {
                          var media = calls[index];
                          return ListTile(
                            leading: const Icon(Icons.call),
                            title: Text(media['title'] ?? 'Call ${index + 1}'),
                            onTap: () {
                              // Handle media tap
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ] else ...[
                  const Center(
                    child: Text('Nenhuma mídia ou chamada disponível',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
