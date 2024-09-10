import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social/widgets/story/action_bar.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final TextEditingController _storyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final profilePictureUrl = userData?['profile_picture'] ?? '';

      String? imageUrl;
      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('story_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      try {
        await FirebaseFirestore.instance.collection('stories').add({
          'user_id': user.uid,
          'username': user.displayName ?? 'Unknown',
          'user_photo': profilePictureUrl,
          'story_content': _storyController.text,
          'image_url': imageUrl ?? '',
          'created_at': Timestamp.now(),
        });
        _storyController.clear();
        setState(() {
          _image = null;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading story: $e');
        }
      }
    }
  }

  Future<void> _deleteStory(String storyId) async {
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Momentos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Stories Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .where('user_id', isEqualTo: currentUserId)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Não há momentos disponíveis.'));
                  }

                  final stories = snapshot.data!.docs;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story =
                          stories[index].data() as Map<String, dynamic>?;
                      final storyId = stories[index].id;
                      final userName = story?['username'] ?? 'Unknown';
                      final userPhoto = story?['user_photo'] ?? '';
                      final storyContent = story?['story_content'] ?? '';
                      final imageUrl = story?['image_url'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: userPhoto.isNotEmpty
                                        ? NetworkImage(userPhoto)
                                        : null,
                                    child: userPhoto.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    userName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  if (imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        imageUrl,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    storyContent,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Confirmar Exclusão'),
                                        content: const Text(
                                            'Tem certeza de que deseja excluir esta história?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Excluir'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete == true) {
                                    await _deleteStory(storyId);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Add Story Section
            const SizedBox(height: 10),
            if (_image != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      _image!,
                      height: 200,
                      width: MediaQuery.of(context).size.width - 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            StoryActionBar(
              storyController: _storyController,
              onPickImage: _pickImage,
              onUploadStory: _uploadStory,
            ),
          ],
        ),
      ),
    );
  }
}
