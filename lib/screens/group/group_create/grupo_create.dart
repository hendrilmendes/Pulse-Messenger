import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// Função para escrever a imagem no armazenamento
Future<String> writeImageToStorage(Uint8List feedbackScreenshot) async {
  final Directory output = await getTemporaryDirectory();
  final String screenshotFilePath = '${output.path}/feedback.png';
  final File screenshotFile = File(screenshotFilePath);
  await screenshotFile.writeAsBytes(feedbackScreenshot);
  return screenshotFilePath;
}

class CreateGroupScreen extends StatefulWidget {
  final List<String> selectedContacts;

  const CreateGroupScreen({super.key, required this.selectedContacts});

  @override
  // ignore: library_private_types_in_public_api
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  XFile? _groupImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _groupImage = image;
      });
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text;
    final groupDescription = _groupDescriptionController.text;

    if (groupName.isEmpty || widget.selectedContacts.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final groupId = FirebaseFirestore.instance.collection('chats').doc().id;

    String? imageUrl;
    if (_groupImage != null) {
      final storageRef =
          FirebaseStorage.instance.ref().child('group_images/$groupId');
      final uploadTask = storageRef.putFile(File(_groupImage!.path));
      final taskSnapshot = await uploadTask;
      imageUrl = await taskSnapshot.ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('chats').doc(groupId).set({
      'group_name': groupName,
      'group_description': groupDescription,
      'group_image': imageUrl,
      'is_group': true,
      'participants': [...widget.selectedContacts, currentUserId],
      'admin': currentUserId,
      'last_message': '',
      'last_message_time': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar Grupo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _createGroup,
            icon: const Icon(Icons.check),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: _groupImage != null
                  ? FileImage(File(_groupImage!.path))
                  : null,
              child: _groupImage == null
                  ? Icon(Icons.camera_alt, size: 30, color: Colors.grey[800])
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Grupo',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Participantes Selecionados:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            itemCount: widget.selectedContacts.length,
            itemBuilder: (context, index) {
              final userId = widget.selectedContacts[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserData(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ListTile(
                      title: Text('Carregando...'),
                    );
                  }

                  final userData = snapshot.data!;
                  final username =
                      userData['username'] ?? 'Usuário Desconhecido';
                  final profilePicture = userData['profile_picture'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : null,
                      child: profilePicture.isEmpty
                          ? Text(username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(username),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
