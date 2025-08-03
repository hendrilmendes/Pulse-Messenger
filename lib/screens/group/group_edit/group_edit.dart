import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditGroupScreen extends StatefulWidget {
  final String chatId;
  final String currentGroupName;
  final String currentGroupDescription;
  final String currentGroupPhotoUrl;

  const EditGroupScreen({
    super.key,
    required this.chatId,
    required this.currentGroupName,
    required this.currentGroupDescription,
    required this.currentGroupPhotoUrl,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _photoUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentGroupName;
    _descriptionController.text = widget.currentGroupDescription;
    _photoUrl = widget.currentGroupPhotoUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('group_photos')
        .child('${widget.chatId}.jpg');

    setState(() {
      isLoading = true;
    });

    try {
      await storageRef.putFile(file);
      final photoUrl = await storageRef.getDownloadURL();
      setState(() {
        _photoUrl = photoUrl;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Erro ao carregar a imagem: $error');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateGroupData() async {
    final name = _nameController.text;
    final description = _descriptionController.text;

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
            'group_image': _photoUrl ?? widget.currentGroupPhotoUrl,
          });
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (error) {
      if (kDebugMode) {
        print('Erro ao atualizar os dados do grupo: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Grupo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateGroupData,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _photoUrl != null
                                ? CachedNetworkImageProvider(_photoUrl!)
                                : widget.currentGroupPhotoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                  widget.currentGroupPhotoUrl,
                                )
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                        child:
                            _photoUrl == null
                                ? const Icon(Icons.camera_alt)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Grupo',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                  ],
                ),
              ),
    );
  }
}
