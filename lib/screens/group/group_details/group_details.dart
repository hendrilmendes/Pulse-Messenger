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
  bool isAdmin = false;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  String? adminId;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    try {
      groupData =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .get();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      setState(() {
        isLoading = false;
        adminId = groupData.data()?['admin']; // Captura o ID do admin
        isAdmin = adminId == currentUserId;
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

  Future<void> leaveGroup() async {
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
    if (!isAdmin) {
      return;
    }

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
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas o administrador pode editar o grupo.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.3,
          maxChildSize: 0.9,
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

  void _addMembers() async {
    // Aqui você pode buscar todos os usuários para mostrar em uma lista
    final allUsersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    final allUsers = allUsersSnapshot.docs.map((doc) => doc.data()).toList();

    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: const BoxDecoration(
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
                      child: Column(
                        children: [
                          AppBar(
                            title: const Text(
                              'Adicionar Membros',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            centerTitle: true,
                            automaticallyImplyLeading: false,
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: allUsers.length,
                              itemBuilder: (context, index) {
                                final user = allUsers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        user['profile_picture'] != null &&
                                                user['profile_picture']
                                                    .isNotEmpty
                                            ? CachedNetworkImageProvider(
                                              user['profile_picture'],
                                            )
                                            : const AssetImage(
                                                  'assets/default_avatar.png',
                                                )
                                                as ImageProvider,
                                  ),
                                  title: Text(user['username']),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _addMemberToGroup(
                                        user['userId'],
                                      ); // Adicione o ID do usuário aqui
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

  Future<void> _addMemberToGroup(String userId) async {
    if (userId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
          'participants': FieldValue.arrayUnion([userId]),
        });

    // Fechar o modal após adicionar
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
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
        actions: [
          if (isAdmin) // Exibe o botão de edição apenas para o administrador
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _editGroup(context);
              },
            ),
          if (isAdmin) // Exibe o botão de adicionar membros apenas para o administrador
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _addMembers,
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
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
                                    groupData.data()!['group_image'],
                                  )
                                  : const AssetImage(
                                        'assets/default_avatar.png',
                                      )
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
                    const Divider(),
                    const Text(
                      'Membros:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator.adaptive(),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(
                            child: Text('Nenhum dado encontrado'),
                          );
                        }

                        final participants = List<String>.from(
                          snapshot.data!.data()?['participants'] ?? [],
                        );
                        participants.sort((a, b) {
                          if (a == adminId) return -1;
                          if (b == adminId) return 1;
                          return 0;
                        });

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final participantId = participants[index];
                            return FutureBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(participantId)
                                      .get(),
                              builder: (context, participantSnapshot) {
                                if (participantSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    title: Text('Carregando...'),
                                  );
                                }

                                if (!participantSnapshot.hasData ||
                                    !participantSnapshot.data!.exists) {
                                  return const ListTile(
                                    title: Text('Usuário não encontrado'),
                                  );
                                }

                                final isGroupAdmin = participantId == adminId;

                                final participantData =
                                    participantSnapshot.data!.data();
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        participantData?['profile_picture'] !=
                                                null
                                            ? CachedNetworkImageProvider(
                                              participantData!['profile_picture'],
                                            )
                                            : const AssetImage(
                                                  'assets/default_avatar.png',
                                                )
                                                as ImageProvider,
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        participantData?['username'] ??
                                            'Desconhecido',
                                      ),
                                      if (isGroupAdmin)
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            height: 30,
                                            width: 60,
                                            child: Card(
                                              child: Center(
                                                child: Text(
                                                  'Admin',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
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
                      },
                    ),
                    const SizedBox(height: 20),
                    if (widget.isGroup)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: leaveGroup,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Sair do Grupo'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
