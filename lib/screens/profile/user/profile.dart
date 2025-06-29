import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: const Text("Perfil"),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.more_horiz),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildStoriesSection(),
            const SizedBox(height: 16),
            const TabBar(
              indicatorColor: Colors.blue,
              tabs: [Tab(text: 'Depoimentos'), Tab(text: 'Publicações')],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [_buildDepoimentosTab(), _buildPublicacoesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Felipe Antônio",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(width: 4),
            Icon(Icons.verified, color: Colors.blue, size: 18),
          ],
        ),
        const Text("@felipeantonio", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Desenvolvedor apaixonado por tecnologia, café e viagens. 🧑‍💻✈️☕",
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
            ),
            SizedBox(width: 4),
            CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
            ),
            SizedBox(width: 4),
            CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
            ),
            SizedBox(width: 8),
            Text("999 amigos"),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Adicionar amigo",
            style: TextStyle(color: Colors.white),
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
        itemBuilder: (context, index) {
          final story = stories[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (_) => Dialog(
                      child: Image.network(story['image']!, fit: BoxFit.cover),
                    ),
              );
            },
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    story['image']!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                Text(story['title']!, style: const TextStyle(fontSize: 12)),
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
          subtitle: Text(
            "Uma pessoa muito especial e que eu adorei conhecer, amizade de milhões.",
          ),
          trailing: Text("1h", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  static Widget _buildPublicacoesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (_, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://i.imgur.com/QCNbOAo.png',
                  ),
                ),
                title: const Text("Felipe"),
                subtitle: const Text("Hoje às 12:00"),
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
