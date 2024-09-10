import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bioController = TextEditingController();
  final _usernameController = TextEditingController();
  String _profilePictureUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _profilePictureUrl = data['profile_picture'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _usernameController.text = data['username'] ?? '';
      });
    }
  }

  Future<void> _saveChanges() async {
    final bio = _bioController.text;
    final username = _usernameController.text;

    // Verifica a unicidade do nome de usuário
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty &&
        querySnapshot.docs.first.id != widget.userId) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este nome de usuário já está em uso.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'profile_picture': _profilePictureUrl,
      'bio': bio,
      'username': username,
    });

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = pickedFile.name;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      try {
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _profilePictureUrl = downloadUrl;
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Imagem de perfil atualizada com sucesso!')),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao carregar a imagem.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePictureUrl.isNotEmpty
                      ? NetworkImage(_profilePictureUrl)
                      : const AssetImage('assets/placeholder.png')
                          as ImageProvider,
                  child: _profilePictureUrl.isEmpty
                      ? const Icon(Icons.camera_alt,
                          size: 50, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nome de Usuário',
              ),
            ),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
