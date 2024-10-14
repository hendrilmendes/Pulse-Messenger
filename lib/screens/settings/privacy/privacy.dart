import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  PrivacyScreenState createState() => PrivacyScreenState();
}

class PrivacyScreenState extends State<PrivacyScreen> {
  List<Map<String, dynamic>> blockedContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedContacts();
  }

  Future<void> _fetchBlockedContacts() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        List blockedUsers = userDoc['blocked_users'] ?? [];

        // Para cada usuário bloqueado, buscamos o nome e os dados
        List<Map<String, dynamic>> contacts = [];
        for (String blockedUserId in blockedUsers) {
          DocumentSnapshot blockedUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(blockedUserId)
              .get();

          if (blockedUserDoc.exists) {
            contacts.add({
              'userId': blockedUserDoc.id,
              'username': blockedUserDoc['username'],
              'profile_picture': blockedUserDoc['profile_picture'],
            });
          }
        }

        setState(() {
          blockedContacts = contacts;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao buscar contatos bloqueados: $e");
      }
    }
  }

  Future<void> _unblockUser(String userId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'blocked_users': FieldValue.arrayRemove([userId])
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário desbloqueado com sucesso!')),
        );

        _fetchBlockedContacts(); // Atualiza a lista após desbloquear
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao desbloquear usuário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.privacy,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Seção: Contas bloqueadas
          _buildSectionTitle('Contas bloqueadas'),
          _buildBlockedContactsList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBlockedContactsList() {
    if (blockedContacts.isEmpty) {
      return const Center(
        child: Text(
          'Você não tem contatos bloqueados.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: blockedContacts.map((contact) {
        return ListTile(
          leading: contact['profile_picture'].isNotEmpty
              ? CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(contact['profile_picture']),
                  radius: 24,
                )
              : const Icon(Icons.person, color: Colors.red),
          title: Text(contact['username']),
          trailing: const Icon(Icons.delete, color: Colors.red),
          onTap: () => _unblockUser(contact['userId']),
        );
      }).toList(),
    );
  }
}
