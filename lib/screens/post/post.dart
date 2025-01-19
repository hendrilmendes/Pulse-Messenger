import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  File? _selectedFile;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final ImagePicker _picker = ImagePicker();
  String? _fileType;

  Future<void> _showPickOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text(AppLocalizations.of(context)!.postImage),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(ImageSource.gallery, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: Text(AppLocalizations.of(context)!.postVideo),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(ImageSource.gallery, 'video');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile(ImageSource source, String type) async {
    final pickedFile = type == 'video'
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileType = type;

        if (_fileType == 'video') {
          _initializeVideo(_selectedFile!);
        } else {
          if (_videoPlayerController != null) {
            _videoPlayerController!.dispose();
            _videoPlayerController = null;
          }
          if (_chewieController != null) {
            _chewieController!.dispose();
            _chewieController = null;
          }
        }
      });
    }
  }

  void _initializeVideo(File videoFile) {
    _videoPlayerController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        if (mounted) {
          final aspectRatio = _videoPlayerController!.value.aspectRatio;

          double adjustedAspectRatio;
          if (aspectRatio > 1) {
            adjustedAspectRatio = aspectRatio;
          } else {
            adjustedAspectRatio = 1 / aspectRatio;
          }

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: false,
            looping: false,
            showControls: true,
            allowFullScreen: false,
            aspectRatio: adjustedAspectRatio,
          );

          setState(() {});
        }
      }).catchError((error) {
        if (kDebugMode) {
          print('Erro ao carregar vídeo: $error');
        }
      });
  }

  Future<String> _uploadFile(File file) async {
    final storageRef = FirebaseStorage.instance.ref();
    final fileExtension = _fileType == 'video' ? 'mp4' : 'jpg';
    final fileName =
        'posts/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final fileRef = storageRef.child(fileName);

    try {
      final uploadTask = fileRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();
      return fileUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao fazer upload do arquivo: $e');
      }
      rethrow;
    }
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para postar.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final content = _contentController.text;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final username = userData?['username'] ?? 'Anonymous';
      final userPhotoUrl = userData?['profile_picture'] ?? '';

      String? fileUrl;
      if (_selectedFile != null) {
        fileUrl = await _uploadFile(_selectedFile!);
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'content': content,
        'file_url': fileUrl,
        'file_type': _fileType,
        'created_at': Timestamp.now(),
        'likes': [],
        'comments': [],
        'user_id': user.uid,
        'username': username,
        'user_photo': userPhotoUrl,
      });

      _contentController.clear();
      setState(() {
        _selectedFile = null;
        _fileType = null;
        if (_videoPlayerController != null) {
          _videoPlayerController!.dispose();
          _videoPlayerController = null;
        }
        if (_chewieController != null) {
          _chewieController!.dispose();
          _chewieController = null;
        }
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
      if (kDebugMode) {
        print('Erro: $e');
      }
    } finally {
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> deletePost(String postId, String fileUrl) async {
    try {
      // Excluir o post do Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      // Excluir o arquivo do Firebase Storage
      final fileRef = FirebaseStorage.instance.refFromURL(fileUrl);
      await fileRef.delete();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post excluído com sucesso.')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao excluir o post: $e');
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir o post: $e')),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.createPost,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _showPickOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedFile != null
                        ? DecorationImage(
                            image: FileImage(_selectedFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedFile == null
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.selectFile,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : _fileType == 'video' && _chewieController != null
                          ? Chewie(
                              controller: _chewieController!,
                            )
                          : _fileType == 'image'
                              ? Image.file(
                                  _selectedFile!,
                                  fit: BoxFit.cover,
                                )
                              : Container(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.content,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  prefixIcon:
                      const Icon(Icons.content_paste, color: Colors.blue),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.insertContent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isSubmitting)
                Center(
                  child: CircularProgressIndicator.adaptive(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(AppLocalizations.of(context)!.post),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
