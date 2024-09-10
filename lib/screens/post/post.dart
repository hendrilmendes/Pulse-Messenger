// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();
  String? _fileType; // 'image' or 'video'

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
                title: const Text('Postar Imagem'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(ImageSource.gallery, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Postar Vídeo'),
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
          _videoController = VideoPlayerController.file(_selectedFile!)
            ..initialize().then((_) {
              setState(() {});
            }).catchError((error) {
              if (kDebugMode) {
                print('Error initializing video controller: $error');
              }
            });
        } else {
          if (_videoController != null) {
            _videoController!.dispose();
            _videoController = null;
          }
        }
      });
    }
  }

  Future<String> _uploadFile(File file) async {
    final storageRef = FirebaseStorage.instance.ref();
    final fileExtension = _fileType == 'video' ? 'mp4' : 'jpg';
    final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
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
        print('Error uploading file: $e');
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

    if (!_formKey.currentState!.validate() || _selectedFile == null) return;

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

      final fileUrl = await _uploadFile(_selectedFile!);

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
        if (_videoController != null) {
          _videoController!.dispose();
          _videoController = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
      if (kDebugMode) {
        print('Error: $e');
      }
    } finally {
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo para o conteúdo
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.content_paste),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira o conteúdo';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Botão para selecionar o arquivo
              GestureDetector(
                onTap: _showPickOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedFile == null
                      ? Center(
                          child: Icon(Icons.camera_alt,
                              size: 50, color: Colors.grey[700]),
                        )
                      : _fileType == 'image'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  Image.file(_selectedFile!, fit: BoxFit.cover),
                            )
                          : _fileType == 'video' && _videoController != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                )
                              : const Center(
                                  child: CircularProgressIndicator.adaptive()),
                ),
              ),

              const SizedBox(height: 20),

              // Mostrar progresso do upload
              if (_isSubmitting && _uploadProgress < 1.0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                  ),
                ),

              // Botão de envio do post
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : const Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
