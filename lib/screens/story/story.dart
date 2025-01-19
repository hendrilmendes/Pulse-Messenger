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
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final TextEditingController _storyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _mediaFile;
  String? _mediaType;
  Timer? _timer;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void dispose() {
    _storyController.dispose();
    _timer?.cancel();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
        _mediaType = 'video';
        _initializeVideoPlayer(_mediaFile!);
      });
    }
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: true,
          );
        });
      }).catchError((error) {
        if (kDebugMode) {
          print("Erro ao inicializar o vídeo: $error");
        }
      });
  }

  Future<String?> _generateVideoThumbnail(String videoUrl) async {
    final filePath = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 512,
      quality: 100,
    );
    return filePath;
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

      String? mediaUrl;
      String? thumbnailUrl;

      if (_mediaFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('story_media')
            .child(
                '${DateTime.now().toIso8601String()}.${_mediaType == 'video' ? 'mp4' : 'jpg'}');
        await storageRef.putFile(_mediaFile!);
        mediaUrl = await storageRef.getDownloadURL();

        if (_mediaType == 'video') {
          // Gerar miniatura para o vídeo
          final thumbnailPath = await _generateVideoThumbnail(_mediaFile!.path);
          if (thumbnailPath != null) {
            final thumbnailRef = FirebaseStorage.instance
                .ref()
                .child('story_thumbnails')
                .child('${DateTime.now().toIso8601String()}.jpg');
            await thumbnailRef.putFile(File(thumbnailPath));
            thumbnailUrl = await thumbnailRef.getDownloadURL();
          }
        }
      }

      try {
        await FirebaseFirestore.instance.collection('stories').add({
          'user_id': user.uid,
          'username': user.displayName ?? 'Unknown',
          'user_photo': profilePictureUrl,
          'story_content': _storyController.text,
          'media_url': mediaUrl ?? '',
          'thumbnail_url': thumbnailUrl ?? '',
          'media_type': _mediaType ?? 'image',
          'created_at': Timestamp.now(),
          'expires_at':
              Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
          'viewed_by': [],
        });
        _storyController.clear();
        setState(() {
          _mediaFile = null;
          _mediaType = null;
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
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
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
                      final mediaUrl = story?['media_url'] ?? '';
                      final mediaType = story?['media_type'] ?? 'image';
                      final thumbnailUrl = story?['thumbnail_url'] ?? '';

                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: mediaType == 'video'
                                  ? CachedNetworkImage(
                                      imageUrl: thumbnailUrl,
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                      width: double.infinity,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: mediaUrl,
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                      width: double.infinity,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: userPhoto.isNotEmpty
                                    ? NetworkImage(userPhoto)
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
                            // Botão de Excluir
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await _deleteStory(storyId);
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
            if (_mediaFile != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: _mediaType == 'image'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _mediaFile!,
                            height: 200,
                            width: MediaQuery.of(context).size.width - 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _videoController != null &&
                              _videoController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : Container(
                              height: 200,
                              width: MediaQuery.of(context).size.width - 40,
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                ),
              ),
            StoryActionBar(
              storyController: _storyController,
              onPickImage: _pickMedia,
              onPickVideo: _pickVideo,
              onUploadStory: _uploadStory,
            ),
          ],
        ),
      ),
    );
  }
}
