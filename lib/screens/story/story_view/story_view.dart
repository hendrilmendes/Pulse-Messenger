import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryViewsScreen extends StatelessWidget {
  final List<String> viewedBy;

  const StoryViewsScreen({super.key, required this.viewedBy});

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        return {
          'name': userDoc['username'],
          'photo': userDoc['profile_picture'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
    return {'name': 'Unknown', 'photo': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visualizações',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum visualizador encontrado.'));
          }

          final userDataList = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Contagem de visualizações: ${viewedBy.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: userDataList.length,
                  itemBuilder: (context, index) {
                    final userData = userDataList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            userData['photo'] != ''
                                ? NetworkImage(userData['photo'])
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                      ),
                      title: Text(userData['name'] ?? 'Nome desconhecido'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserDetails() async {
    List<Map<String, dynamic>> userDataList = [];
    for (String userId in viewedBy) {
      final userData = await _getUserData(userId);
      userDataList.add(userData);
    }
    return userDataList;
  }
}
