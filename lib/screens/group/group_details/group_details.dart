import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:social/screens/group/group_edit/group_edit.dart';

class GroupDetailsScreen extends StatefulWidget {
  final bool isGroup;
  final String userId;
  final String chatId;

  const GroupDetailsScreen({
    super.key,
    required this.isGroup,
    required this.userId,
    required this.chatId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late DocumentSnapshot<Map<String, dynamic>> groupData;
  bool isLoading = true;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    try {
      groupData = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Erro ao buscar os dados do grupo: $error');
      }
    }
  }

  Future<void> _updateGroupData({
    required String name,
    required String description,
    required String photoUrl,
  }) async {
    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome e descrição não podem estar vazios'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'group_name': name,
        'group_description': description,
        'group_photo_url': photoUrl,
      });
      _fetchGroupData();
    } catch (error) {
      if (kDebugMode) {
        print('Erro ao atualizar os dados do grupo: $error');
      }
    }
  }

  Future<void> _leaveGroup() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'participants': FieldValue.arrayRemove([currentUserId]),
    });

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('group_photos')
        .child('${widget.chatId}.jpg');

    try {
      await storageRef.putFile(file);
      final photoUrl = await storageRef.getDownloadURL();
      _updateGroupData(
        name: groupData.data()?['group_name'] ?? '',
        description: groupData.data()?['group_description'] ?? '',
        photoUrl: photoUrl,
      );
    } catch (error) {
      if (kDebugMode) {
        print('Erro ao carregar a imagem: $error');
      }
    }
  }

  void _editGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    width: MediaQuery.of(context).size.width,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: EditGroupScreen(
                        chatId: widget.chatId,
                        currentGroupName: groupData.data()?['group_name'] ?? '',
                        currentGroupDescription:
                            groupData.data()?['group_description'] ?? '',
                        currentGroupPhotoUrl:
                            groupData.data()?['group_image'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Grupo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _editGroup(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            groupData.data()?['group_image'] != null &&
                                    groupData.data()?['group_image'] != ''
                                ? CachedNetworkImageProvider(
                                    groupData.data()!['group_image'])
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                        radius: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        groupData.data()?['group_name'] ?? 'Grupo',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (groupData.data()?['group_description'] != null)
                    Text(
                      groupData.data()?['group_description'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'Criado em: ${groupData.data()?['created_at'] != null ? dateFormat.format(groupData.data()!['created_at'].toDate()) : 'Desconhecido'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Administrador: ${groupData.data()?['admin_id'] ?? 'Desconhecido'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Participantes:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text('Nenhum dado encontrado'),
                        );
                      }

                      final groupData = snapshot.data!.data();
                      final participants =
                          List<String>.from(groupData?['participants'] ?? []);

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participantId = participants[index];

                          return FutureBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(participantId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                  leading: CircleAvatar(
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                  title: Text('Carregando...'),
                                );
                              }

                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text('Usuário Desconhecido'),
                                );
                              }

                              final userData = userSnapshot.data!.data();
                              final userName =
                                  userData?['username'] ?? 'Usuário';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      userData?['profile_picture'] != null
                                          ? CachedNetworkImageProvider(
                                              userData!['profile_picture'])
                                          : null,
                                  child: userData?['profile_picture'] == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(userName),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (widget.isGroup)
                    ElevatedButton.icon(
                      onPressed: _leaveGroup,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Sair do Grupo'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
