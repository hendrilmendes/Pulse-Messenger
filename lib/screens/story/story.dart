import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  Timer? _timer;

  @override
  void dispose() {
    _storyController.dispose();
    _timer?.cancel();
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
          'expires_at':
              Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
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

  Future<void> _removeExpiredStories() async {
    final now = Timestamp.now();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('expires_at', isLessThanOrEqualTo: now)
        .get();

    for (var doc in querySnapshot.docs) {
      await _deleteStory(doc.id);
    }
  }

  @override
  void initState() {
    super.initState();
    _removeExpiredStories();

    _timer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _removeExpiredStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.postMomment,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
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
                    return Center(
                        child: Text(AppLocalizations.of(context)!.noMomment));
                  }

                  final stories = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story =
                          stories[index].data() as Map<String, dynamic>?;
                      final storyId = stories[index].id;
                      final userPhoto = story?['user_photo'] ?? '';
                      final storyContent = story?['story_content'] ?? '';
                      final imageUrl = story?['image_url'] ?? '';

                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                      width: double.infinity,
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(Icons.image,
                                            size: 40, color: Colors.grey[600]),
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: userPhoto.isNotEmpty
                                    ? CachedNetworkImageProvider(userPhoto)
                                    : null,
                                child: userPhoto.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            
                            if (storyContent.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    storyContent,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final appLocalizations =
                                      AppLocalizations.of(context);
                                  if (appLocalizations != null) {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                              appLocalizations.deleteConfirm),
                                          content: Text(
                                              appLocalizations.deleteMomment),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child:
                                                  Text(appLocalizations.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child:
                                                  Text(appLocalizations.delete),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (shouldDelete == true) {
                                      await _deleteStory(storyId);
                                    }
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
