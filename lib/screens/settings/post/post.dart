import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/screens/post/post_details/post_details.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ManagePostsScreen extends StatelessWidget {
  const ManagePostsScreen({super.key});

  Future<void> _deletePost(BuildContext context, String postId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Não permite fechar a caixa de diálogo ao tocar fora dela
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Você tem certeza de que deseja excluir esta postagem?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Retorna false para não excluir
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Retorna true para excluir
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Se o usuário confirmar, exclua o post do Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }

  Future<Widget> _generateVideoThumbnail(String videoUrl) async {
    final thumbnail = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 800, // Aumente o tamanho conforme necessário
      quality: 75,
    );

    if (thumbnail != null) {
      return Image.memory(thumbnail, fit: BoxFit.cover);
    } else {
      return const Center(child: Icon(Icons.video_library, size: 50, color: Colors.grey));
    }
  }

  void _openPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PostDetailsScreen(
          postId: postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerenciar Postagens',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('user_id', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma postagem encontrada'));
          }

          final posts = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.75,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post.id;
              final postContent = post['content'];
              final userPhoto = post['user_photo'] ?? '';
              final mediaUrl = post['file_url'] ?? '';
              final mediaType = post['file_type'] ?? 'text';

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.visibility),
                            title: const Text('Ver Postagem'),
                            onTap: () => _openPost(context, post.id),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text('Excluir Postagem'),
                            onTap: () {
                              Navigator.of(context).pop(); // Fecha o bottom sheet
                              _deletePost(context, postId);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Stack(
                    children: [
                      if (mediaType == 'image' && mediaUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: CachedNetworkImage(
                            imageUrl: mediaUrl,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        )
                      else if (mediaType == 'video' && mediaUrl.isNotEmpty)
                        FutureBuilder<Widget>(
                          future: _generateVideoThumbnail(mediaUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: SizedBox.expand(
                                child: snapshot.data ?? const SizedBox.shrink(),
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Text(
                              postContent,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: userPhoto.isNotEmpty
                              ? CachedNetworkImageProvider(userPhoto)
                              : null,
                          child: userPhoto.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            postContent,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
