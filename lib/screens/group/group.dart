import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social/screens/group_details/group_details.dart';
import 'package:social/widgets/chat/action_bar.dart';
import 'package:social/widgets/chat/full_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class GroupChatScreen extends StatefulWidget {
  final bool isGroup;
  final String chatId;
  final String userId;

  const GroupChatScreen({
    super.key,
    required this.isGroup,
    required this.chatId,
    required this.userId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<Map<String, dynamic>> _groupData;

  final _record = AudioRecorder();
  bool _isRecording = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _playingAudioUrl;

  @override
  void initState() {
    super.initState();
    _groupData = _fetchGroupData();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          isPaused = state == PlayerState.paused;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<Map<String, dynamic>> _fetchGroupData() async {
    final doc = await _firestore.collection('chats').doc(widget.chatId).get();
    return doc.data() ?? {};
  }

  Future<void> _sendMessage(String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || message.trim().isEmpty) return;

    _messageController.clear();

    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'sender_id': currentUser.uid,
      'sender_name': currentUser.displayName ?? 'Desconhecido',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(widget.chatId).update({
      'last_message': message,
      'last_message_time': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendAudio(File audioFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audios/${DateTime.now().millisecondsSinceEpoch}.m4a');
      final uploadTask = storageRef.putFile(audioFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'audio': downloadUrl,
        'sender_id': _auth.currentUser!.uid,
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': 'Mensagem de Áudio',
        'last_message_time': Timestamp.now(),
        'unread_count': FieldValue.increment(1),
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending audio: $e')),
      );
    }
  }

  void showMedia(BuildContext context, String url, bool isVideo) {
    // Verifica se o URL é um URL de rede válido
    bool isNetworkUrl = url.startsWith('http') || url.startsWith('https');
    if (isNetworkUrl) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return FullScreenMedia(url: url, isVideo: isVideo);
        },
      );
    } else {
      // Trate o caso em que o URL não é uma URL de rede
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválido para exibição.')),
      );
    }
  }

  Future<void> _sendMedia({required bool fromGallery}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media, // Permite fotos e vídeos
        allowMultiple:
            true, // Se quiser permitir seleção múltipla, mude para true
      );

      if (result == null || result.files.isEmpty) {
        throw 'Nenhuma mídia selecionada';
      }

      final pickedFile = result.files.first;
      final file = File(pickedFile.path!);

      bool isVideo = pickedFile.extension == 'mp4' ||
          pickedFile.extension == 'mov'; // Verifique se é vídeo ou imagem
      final storageRef = FirebaseStorage.instance.ref().child(
          '${isVideo ? 'videos' : 'images'}/${DateTime.now().millisecondsSinceEpoch}.${pickedFile.extension}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        isVideo ? 'video' : 'image': downloadUrl,
        'sender_id': _auth.currentUser!.uid,
        'timestamp': Timestamp.now(),
        'read': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': isVideo ? 'Vídeo' : 'Imagem',
        'last_message_time': Timestamp.now(),
        'unread_count': FieldValue.increment(1),
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _startRecording() async {
    if (await _record.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _record.start(const RecordConfig(), path: path);
      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording permission denied')),
      );
    }
  }

  void _stopRecording() async {
    final filePath = await _record.stop();
    if (filePath != null) {
      final file = File(filePath);
      await _sendAudio(file);
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  void playAudio(String audioUrl) async {
    if (_playingAudioUrl != null && _playingAudioUrl != audioUrl) {
      stopAudio();
    }
    try {
      await _audioPlayer.setSource(UrlSource(audioUrl));
      await _audioPlayer.resume();
      if (mounted) {
        setState(() {
          _isPlaying = true;
          isPaused = false;
          _playingAudioUrl = audioUrl; // Atualize o URL do áudio tocando
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  void stopAudio() async {
    try {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          isPaused = false;
          _currentPosition = Duration.zero;
          _playingAudioUrl = null; // Limpe o URL do áudio tocando
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping audio: $e')),
      );
    }
  }

  void pauseAudio() async {
    try {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          isPaused = true;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing audio: $e')),
      );
    }
  }

  void _navigateToGroupDetails() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => GroupDetailsScreen(
          chatId: widget.chatId,
          isGroup: widget.isGroup,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<Widget> _buildVideoThumbnail(String videoUrl) async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 150, // Tamanho máximo da largura da miniatura
      quality: 75,
    );

    if (uint8list == null) {
      return const Icon(Icons.error);
    }

    return SizedBox(
      width: 150,
      height: 150,
      child: Image.memory(
        uint8list,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _groupData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Carregando...');
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Text('Grupo');
            }

            final groupData = snapshot.data!;
            final groupName = groupData['group_name'] ?? 'Grupo';
            final groupPhotoUrl = groupData['group_image'] ?? '';

            return GestureDetector(
              onTap: _navigateToGroupDetails,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: groupPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(groupPhotoUrl)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      groupName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma mensagem ainda',
                          style: TextStyle(fontSize: 16)));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final messageData = snapshot.data!.docs[index];
                    final isCurrentUser =
                        messageData['sender_id'] == _auth.currentUser?.uid;
                    return _buildMessageBubble(messageData, isCurrentUser);
                  },
                );
              },
            ),
          ),
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Gravando...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ActionBar(
            isRecording: _isRecording,
            onCameraPressed: () => _sendMedia(fromGallery: false),
            onGalleryPressed: () => _sendMedia(fromGallery: true),
            onVideoPressed: () => _sendMedia(fromGallery: false),
            onRecordPressed: _isRecording ? _stopRecording : _startRecording,
            onSendMessage: _sendMessage,
            messageController: _messageController,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot messageData, bool isCurrentUser) {
    final data = messageData.data() as Map<String, dynamic>?;

    final senderName = data != null && data.containsKey('sender_name')
        ? data['sender_name']
        : 'Desconhecido';

    final senderId = data?['sender_id'] ?? 'unknown_sender';
    final messageText =
        data?.containsKey('message') == true ? data!['message'] : '';
    final imageUrl = data?.containsKey('image') == true ? data!['image'] : null;
    final videoUrl = data?.containsKey('video') == true ? data!['video'] : null;
    final audioUrl = data?.containsKey('audio') == true ? data!['audio'] : null;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 250, // Set maximum width for the bubble
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(senderId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final userPhotoUrl = userData['profile_picture'] ?? '';
                      return CircleAvatar(
                        backgroundImage: userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(userPhotoUrl)
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider,
                        radius: 15,
                      );
                    }
                    return const CircleAvatar(radius: 15);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    senderName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (messageText.isNotEmpty) _buildMessageText(messageText),
            if (imageUrl != null)
              GestureDetector(
                onTap: () => showMedia(context, imageUrl, false),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 150, // Set fixed height to prevent stretching
                  width: 150, // Set fixed width to prevent stretching
                  fit: BoxFit.cover,
                ),
              ),
            if (videoUrl != null)
              GestureDetector(
                onTap: () => showMedia(context, videoUrl, true),
                child: FutureBuilder<Widget>(
                  future: _buildVideoThumbnail(videoUrl),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        height: 150, // Set fixed height for video
                        width: 150, // Set fixed width for video
                        child: snapshot.data!,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            if (audioUrl != null)
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying && _playingAudioUrl == audioUrl
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () {
                      if (_isPlaying && _playingAudioUrl == audioUrl) {
                        pauseAudio();
                      } else {
                        playAudio(audioUrl);
                      }
                    },
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _isPlaying && _playingAudioUrl == audioUrl
                          ? _currentPosition.inMilliseconds /
                              _totalDuration.inMilliseconds
                          : 0,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

// Helper for Avatar
  Widget buildSenderAvatar(String senderId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(senderId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userPhotoUrl = userData['profile_picture'] ?? '';
          return CircleAvatar(
            backgroundImage: userPhotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(userPhotoUrl)
                : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
            radius: 16,
          );
        }
        return const CircleAvatar(radius: 16);
      },
    );
  }

// Helper for Message Text
  Widget _buildMessageText(String messageText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        messageText,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

// Helper for Image Content
  Widget buildImageContent(String imageUrl) {
    return GestureDetector(
      onTap: () => showMedia(context, imageUrl, false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200, // Limit maximum height
            maxWidth: 200, // Limit maximum width
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

// Helper for Video Content
  Widget buildVideoContent(String videoUrl) {
    return GestureDetector(
      onTap: () => showMedia(context, videoUrl, true),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 200, // Limit maximum height for videos
          maxWidth: 200, // Limit maximum width for videos
        ),
        child: FutureBuilder<Widget>(
          future: _buildVideoThumbnail(videoUrl),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }

// Helper for Audio Content
  Widget buildAudioContent(String audioUrl) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying && _playingAudioUrl == audioUrl
              ? Icons.pause
              : Icons.play_arrow),
          onPressed: () {
            if (_isPlaying && _playingAudioUrl == audioUrl) {
              pauseAudio();
            } else {
              playAudio(audioUrl);
            }
          },
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: _isPlaying && _playingAudioUrl == audioUrl
                ? _currentPosition.inMilliseconds /
                    _totalDuration.inMilliseconds
                : 0,
          ),
        ),
      ],
    );
  }

// Helper for Timestamp
  Widget buildTimestamp(dynamic timestamp) {
    if (timestamp == null) return const SizedBox();
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
    return Text(
      DateFormat('HH:mm').format(time),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}
