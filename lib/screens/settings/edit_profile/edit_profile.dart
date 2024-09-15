// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.existentUser)),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.updateImageProfile)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.errorImageProfile)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Seção de Edição de Imagem de Perfil
          _buildSectionTitle(AppLocalizations.of(context)!.imageProfile),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profilePictureUrl.isNotEmpty
                    ? CachedNetworkImageProvider(_profilePictureUrl)
                    : const AssetImage('assets/placeholder.png')
                        as ImageProvider,
                child: _profilePictureUrl.isEmpty
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção de Informações do Perfil
          _buildSectionTitle(AppLocalizations.of(context)!.profileInformation),
          _buildListTile(
            icon: Icons.person,
            title: AppLocalizations.of(context)!.userName,
            subtitle: AppLocalizations.of(context)!.changueUserName,
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.insertUserName),
            ),
          ),
          _buildListTile(
            icon: Icons.info,
            title: AppLocalizations.of(context)!.bio,
            subtitle: AppLocalizations.of(context)!.changeBio,
            child: TextField(
              controller: _bioController,
              decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.insertBio),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.blueAccent),
            title: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(subtitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
