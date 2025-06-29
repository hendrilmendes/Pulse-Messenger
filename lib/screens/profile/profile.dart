import 'package:flutter/material.dart';
import 'package:social/models/profile_model.dart';
import 'package:social/services/profile/profile.dart';
import 'package:social/widgets/avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService().getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text("Perfil"),
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          } else if (snap.hasData) {
            return _buildProfile(context, snap.data!);
          } else {
            return const Center(child: Text('Perfil não encontrado'));
          }
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, UserProfile user) {
    return Column(
      children: [
        const SizedBox(height: 16),
        UserAvatar(radius: 50, photoUrl: user.avatar, displayName: user.name),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Colors.blue, size: 18),
          ],
        ),
        Text('@${user.username}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        _buildStoriesSection(),
        const SizedBox(height: 16),
        const TabBar(
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Depoimentos'),
            Tab(text: 'Publicações'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            children: [_buildDepoimentosTab(), _buildPublicacoesTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildStoriesSection() {
    final stories = [
      {'title': 'Viagem', 'image': 'https://i.imgur.com/x0rlGWW.jpg'},
      {'title': 'Amigos', 'image': 'https://i.imgur.com/K0C49Qm.jpg'},
      {'title': 'Pets', 'image': 'https://i.imgur.com/NIbE0av.jpg'},
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = stories[i];
          return GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) =>
                  Dialog(child: Image.network(s['image']!, fit: BoxFit.cover)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    s['image']!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                Text(s['title']!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildDepoimentosTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
          ),
          title: Text("Felipe", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Uma pessoa muito especial..."),
          trailing: Text("1h", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  static Widget _buildPublicacoesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (_, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              const ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://i.imgur.com/QCNbOAo.png',
                  ),
                ),
                title: Text("Felipe"),
                subtitle: Text("Hoje às 12:00"),
              ),
              Image.network('https://i.imgur.com/x0rlGWW.jpg'),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Passeio incrível com a galera!"),
              ),
            ],
          ),
        );
      },
    );
  }
}
