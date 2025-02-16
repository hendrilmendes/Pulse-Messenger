import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/widgets/chat/full_view.dart';

class ConversationDetailsScreen extends StatelessWidget {
  final String chatId;
  final String userId;

  const ConversationDetailsScreen({
    super.key,
    required this.chatId,
    required this.userId,
  });

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchMedia() async {
    try {
      QuerySnapshot messagesDocs =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();

      if (kDebugMode) {
        print('Queried documents count: ${messagesDocs.docs.length}');
      }

      List<Map<String, dynamic>> mediaList =
          messagesDocs.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (kDebugMode) {
                  print('Document data: $data');
                }

                if (data.containsKey('audio') && data['audio'] != null) {
                  return {'type': 'audio', 'url': data['audio']};
                } else if (data.containsKey('image') && data['image'] != null) {
                  return {'type': 'image', 'url': data['image']};
                } else if (data.containsKey('video') && data['video'] != null) {
                  return {'type': 'video', 'url': data['video']};
                } else if (data.containsKey('document') &&
                    data['document'] != null) {
                  return {'type': 'document', 'url': data['document']};
                } else {
                  return null;
                }
              })
              .where((data) => data != null)
              .cast<Map<String, dynamic>>()
              .toList();

      if (kDebugMode) {
        print('Filtered media: $mediaList');
      }
      return mediaList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching media: $e');
      }
      return [];
    }
  }

  // Verifica se o usuário já está bloqueado
  Future<bool> _isUserBlocked(String userId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      List blockedUsers =
          userData != null && userData.containsKey('blocked_users')
              ? userData['blocked_users']
              : [];

      return blockedUsers.contains(userId);
    }
    return false;
  }

  // Função para bloquear/desbloquear o usuário
  void _toggleBlockUser(BuildContext context, bool isBlocked) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String currentUserId = currentUser.uid;

        if (isBlocked) {
          // Desbloquear usuário removendo do array
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .update({
                'blocked_users': FieldValue.arrayRemove([userId]),
              });

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário desbloqueado com sucesso!')),
          );
        } else {
          // Bloquear usuário adicionando ao array
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .update({
                'blocked_users': FieldValue.arrayUnion([userId]),
              });

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário bloqueado com sucesso!')),
          );
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar status do usuário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da Conversa',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([
          _fetchUserData(),
          _fetchMedia(),
          _isUserBlocked(userId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nenhum dado disponível.'));
          }

          Map<String, dynamic> userData = snapshot.data![0];
          List<Map<String, dynamic>> mediaList = snapshot.data![1];
          bool isBlocked = snapshot.data![2];

          // Exibir uma mensagem se o usuário estiver bloqueado
          if (isBlocked) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Usuário bloqueado, não é possível visualizar as informações desta conversa.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          List<Map<String, dynamic>> images =
              mediaList.where((media) => media['type'] == 'image').toList();
          List<Map<String, dynamic>> audios =
              mediaList.where((media) => media['type'] == 'audio').toList();
          List<Map<String, dynamic>> videos =
              mediaList.where((media) => media['type'] == 'video').toList();
          List<Map<String, dynamic>> documents =
              mediaList.where((media) => media['type'] == 'document').toList();

          bool hasMedia =
              images.isNotEmpty ||
              audios.isNotEmpty ||
              videos.isNotEmpty ||
              documents.isNotEmpty;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            userData['profile_picture'] ??
                                'https://example.com/default-pic.jpg',
                          ),
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['username'] ?? 'User Name',
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userData['bio'] ?? 'Bio',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                isBlocked ? Colors.green : Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () {
                            _toggleBlockUser(context, isBlocked);
                          },
                          child: Text(isBlocked ? 'Desbloquear' : 'Bloquear'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () {
                            // Add your mute functionality here
                          },
                          child: const Text('Silenciar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (hasMedia) ...[
                    if (images.isNotEmpty) ...[
                      const Text(
                        'Imagens',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                        itemCount: images.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          var media = images[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder:
                                      (context) => FullScreenImageView(
                                        imageUrl: media['url'],
                                      ),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: media['url'],
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator.adaptive(),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    ],
                    if (videos.isNotEmpty) ...[
                      const Divider(thickness: 1, color: Colors.grey),
                      const Text(
                        'Vídeos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  2, // Ajuste o número de colunas conforme necessário
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final media = videos[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: GridTile(
                              footer: GridTileBar(
                                backgroundColor: Colors.black54,
                                title: Text('Vídeo ${index + 1}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder:
                                            (context) => FullScreenVideoPlayer(
                                              videoUrl: media['url'],
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: media['url'],
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        const CircularProgressIndicator.adaptive(),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (documents.isNotEmpty) ...[
                      const Divider(thickness: 1, color: Colors.grey),
                      const Text(
                        'Documentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  2, // Ajuste o número de colunas conforme necessário
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: GridTile(
                              footer: GridTileBar(
                                title: Text('Documento ${index + 1}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () {
                                    // Handle media tap, e.g., open document
                                  },
                                ),
                              ),
                              child: const Icon(
                                Icons.document_scanner,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (audios.isNotEmpty) ...[
                      const Divider(thickness: 1, color: Colors.grey),
                      const Text(
                        'Áudios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  2, // Ajuste o número de colunas conforme necessário
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                        itemCount: audios.length,
                        itemBuilder: (context, index) {
                          final media = audios[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: GridTile(
                              footer: GridTileBar(
                                backgroundColor: Colors.black54,
                                title: const Text('Áudio'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder:
                                            (context) => FullScreenAudioPlayer(
                                              audioUrl: media['url'],
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              child: const Icon(Icons.audio_file, size: 50),
                            ),
                          );
                        },
                      ),
                    ],
                  ] else ...[
                    const Center(
                      child: Text(
                        'Nenhuma mídia disponível',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
