import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/auth_provider.dart';
import 'package:social/screens/profile/user_profile/user_profile.dart';

class FollowManagementScreen extends StatelessWidget {
  const FollowManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Gerenciar Seguidores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0.5,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Seguindo'),
              Tab(text: 'Seguidores'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Lista de usuários que estou seguindo
            _FollowingList(userId: userId),
            // Lista de usuários que me seguem
            _FollowersList(userId: userId),
          ],
        ),
      ),
    );
  }
}

void _showProfileOptions(BuildContext context, String userId, String userName) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                _openUserProfile(context, userId, userName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle),
              title: const Text('Deixar de seguir'),
              onTap: () {
                Navigator.pop(context); // Fechar o bottom sheet
                _unfollowUser(context, userId); // Função para deixar de seguir
              },
            ),
          ],
        ),
      );
    },
  );
}

void _openUserProfile(BuildContext context, String userId, String userName) {
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => UserProfileScreen(
        userId: userId,
        username: userName,
      ),
    ),
  );
}

void _unfollowUser(BuildContext context, String userId) async {
  // Capture o authProvider antes de qualquer mudança no contexto
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUserId = authProvider.currentUser?.uid;

  if (currentUserId != null) {
    await FirebaseFirestore.instance
        .collection('following')
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(userId)
        .delete();

    await FirebaseFirestore.instance
        .collection('followers')
        .doc(userId)
        .collection('userFollowers')
        .doc(currentUserId)
        .delete();

    // Use um Future.delayed para esperar que o modal seja fechado antes de mostrar o SnackBar
    Future.delayed(Duration.zero, () {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deixou de seguir esse usuário.')),
      );
    });
  }
}

// Componente para listar os usuários que estou seguindo
class _FollowingList extends StatelessWidget {
  final String userId;
  const _FollowingList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('following')
          .doc(userId)
          .collection('userFollowing')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Você não está seguindo ninguém.'));
        }

        final followingDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: followingDocs.length,
          itemBuilder: (context, index) {
            final followingUserId = followingDocs[index].id;

            return _buildUserTile(followingUserId);
          },
        );
      },
    );
  }
}

// Componente para listar os usuários que me seguem
class _FollowersList extends StatelessWidget {
  final String userId;
  const _FollowersList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('followers')
          .doc(userId)
          .collection('userFollowers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Você não tem seguidores ainda.'));
        }

        final followersDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: followersDocs.length,
          itemBuilder: (context, index) {
            final followerUserId = followersDocs[index].id;

            return _buildUserTile(followerUserId);
          },
        );
      },
    );
  }
}

// Função para construir o layout dos usuários
Widget _buildUserTile(String userId) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const ListTile(title: Text('Usuário não encontrado.'));
      }

      final userData = snapshot.data!.data() as Map<String, dynamic>;
      final username = userData['username'] ?? 'Usuário';
      final profilePictureUrl = userData['profile_picture'] ?? '';

      return ListTile(
        leading: CircleAvatar(
          backgroundImage: profilePictureUrl.isNotEmpty
              ? NetworkImage(profilePictureUrl)
              : null,
          child: profilePictureUrl.isEmpty ? Text(username[0]) : null,
        ),
        title: Text(username),
        onTap: () {
          _showProfileOptions(context, userId, username);
        },
      );
    },
  );
}
