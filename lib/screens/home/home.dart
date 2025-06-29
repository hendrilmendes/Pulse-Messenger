import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:social/models/post_model.dart';
import 'package:social/screens/home/posts/posts.dart';
import 'package:social/screens/notifications/notifications.dart';
import 'package:social/services/post/post.dart';
import 'package:social/widgets/avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showFab = true;
  final ScrollController _scrollController = ScrollController();
  late Future<List<PostModel>> _postsFuture;

  void _openNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

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
    _postsFuture = PostService().fetchPosts();
    _scrollController.addListener(_onScroll);
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
          title: Row(
            children: [
              Text(
                "Pulse",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(CupertinoIcons.eye),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(CupertinoIcons.bell),
                onPressed: () => _openNotification(context),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Amigos'),
              Tab(text: 'Global'),
              Tab(text: 'Favoritas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeed(context),
            _buildFeed(context),
            _buildFeed(context),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              child: Icon(CupertinoIcons.add),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeed(BuildContext context) {
    return FutureBuilder<List<PostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Exibe um indicador de carregamento enquanto os dados estão sendo buscados
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Exibe uma mensagem de erro caso ocorra algum problema na requisição
          return Center(
            child: Text('Erro ao carregar postagens: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Exibe uma mensagem caso não haja postagens disponíveis
          return const Center(child: Text('Nenhuma postagem disponível.'));
        } else {
          // Exibe a lista de postagens
          final posts = snapshot.data!;
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPost(context, post);
            },
          );
        }
      },
    );
  }

  Widget _buildPost(BuildContext context, PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(radius: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '@${post.username} · ${_formatTime(post.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // Ações adicionais, como compartilhar ou denunciar
              },
              child: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (post.image != null && post.image!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: post.image!.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: post.image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Image.file(
                    File(post.image!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),

        const SizedBox(height: 8),
        Text(
          post.caption,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                _showReactionOptions(context);
              },
              onLongPress: () {
                _showReactionOptions(context);
              },
              child: const Icon(CupertinoIcons.smiley),
            ),
            const SizedBox(width: 20),
            const CircleAvatar(
              radius: 10,
              backgroundImage: NetworkImage('https://i.pravatar.cc/101'),
            ),
            const CircleAvatar(
              radius: 10,
              backgroundImage: NetworkImage('https://i.pravatar.cc/102'),
            ),
            const CircleAvatar(
              radius: 10,
              backgroundImage: NetworkImage('https://i.pravatar.cc/103'),
            ),
            const Spacer(),
            const Icon(CupertinoIcons.chat_bubble),
            const SizedBox(width: 4),
            Text('${post.comments}'),
            const SizedBox(width: 12),
            const Icon(CupertinoIcons.repeat),
            const SizedBox(width: 4),
            Text('${post.reactions}'),
          ],
        ),
      ],
    );
  }

  void _showReactionOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up, color: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
