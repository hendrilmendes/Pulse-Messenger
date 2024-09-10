import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:social/screens/call/call.dart';
import 'package:social/screens/conversation_details/conversation_details.dart';
import 'package:social/screens/video_call/video_call.dart';
import 'package:social/widgets/chat/action_bar.dart';
import 'package:social/widgets/video/video_player.dart'; // Certifique-se de importar seu ActionBar

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const ChatDetailScreen({
    required this.chatId,
    required this.userId,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _record = AudioRecorder();
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late Stream<QuerySnapshot> _messagesStream;
  Map<String, String>? _userData;
  bool _isPlaying = false;
  bool isPaused = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _playingAudioUrl;

  @override
  void initState() {
    super.initState();
    _updateUserStatus('online');
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
    _loadUserData();

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

  @override
  void dispose() {
    _updateUserStatus('offline');
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': text,
        'sender_id': _auth.currentUser!.uid,
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': text,
        'last_message_time': Timestamp.now(),
        'unread_count': FieldValue.increment(1),
      });

      _messageController.clear();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
        'last_message': 'Audio message',
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

  void _showMedia(BuildContext context, String url, bool isVideo) {
    // Verifica se o URL é um URL de rede válido
    bool isNetworkUrl = url.startsWith('http') || url.startsWith('https');
    if (isNetworkUrl) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: isVideo
                ? VideoPlayerWidget(url: url)
                : CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator.adaptive(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    fit: BoxFit.contain,
                  ),
          );
        },
      );
    } else {
      // Trate o caso em que o URL não é uma URL de rede
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválido para exibição.')),
      );
    }
  }

  Future<void> _sendMedia(
      {required bool fromGallery, required bool isVideo}) async {
    final XFile? media = isVideo
        ? await _picker.pickVideo(
            source: fromGallery ? ImageSource.gallery : ImageSource.camera)
        : await _picker.pickImage(
            source: fromGallery ? ImageSource.gallery : ImageSource.camera,
            imageQuality: 100);

    if (media == null) return;

    try {
      final file = File(media.path);
      final storageRef = FirebaseStorage.instance.ref().child(
          '${isVideo ? 'videos' : 'images'}/${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}');
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
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': isVideo ? 'Video message' : 'Image message',
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

  void _pauseAudio() async {
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

  void _callScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: widget.chatId,
          appId: '3d15be3b03ee48b1bb438ea848726a1e',
          userId: widget.userId,
        ),
      ),
    );
  }

  void _callScreen2() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelName: widget.chatId,
          appId: '3d15be3b03ee48b1bb438ea848726a1e',
          isVideoCall: true,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final lastSeen = doc.data()?['last_seen'] as Timestamp?;
      final lastSeenString =
          lastSeen != null ? _formatTimestamp(lastSeen) : 'Unknown';

      if (mounted) {
        setState(() {
          _userData = {
            'username': doc.data()?['username'] ?? 'Unknown',
            'profile_picture': doc.data()?['profile_picture'] ?? '',
            'status': doc.data()?['status'] ?? 'offline',
            'last_seen': lastSeenString,
          };
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  Future<Widget> _buildVideoThumbnail(String videoUrl) async {
    // Verifica se o URL do vídeo é válido
    bool isNetworkUrl =
        videoUrl.startsWith('http') || videoUrl.startsWith('https');
    if (isNetworkUrl) {
      return VideoPlayerWidget(url: videoUrl);
    } else {
      return const Icon(
          Icons.error); // Exibe um ícone de erro se o URL não for válido
    }
  }

  Future<void> _updateUserStatus(String status) async {
    final userId = _auth.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'status': status,
      'last_seen': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationDetailsScreen(
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                    _userData?['profile_picture'] ?? ''),
                radius: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?['username'] ?? 'Unknown User',
                    ),
                    Text(
                      _userData?['status'] == 'online'
                          ? 'Online'
                          : 'Last seen: ${_userData?['last_seen']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: _callScreen),
          IconButton(
              icon: const Icon(Icons.video_call), onPressed: _callScreen2),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Sem mensagens'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final messageDoc = snapshot.data!.docs[index];
                    final messageData =
                        messageDoc.data() as Map<String, dynamic>;
                    final isMe =
                        messageData['sender_id'] == _auth.currentUser!.uid;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  _userData?['profile_picture'] ?? ''),
                              radius: 20,
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (messageData['text'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isMe ? Colors.blue : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      messageData['text'],
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                if (messageData['image'] != null)
                                  GestureDetector(
                                    onTap: () => _showMedia(
                                      context,
                                      messageData['image'],
                                      false,
                                    ),
                                    child: Card(
                                      child: CachedNetworkImage(
                                        imageUrl: messageData['image'],
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (messageData['video'] != null)
                                  GestureDetector(
                                    onTap: () => _showMedia(
                                      context,
                                      messageData['video'],
                                      true,
                                    ),
                                    child: Card(
                                      child: FutureBuilder<Widget>(
                                        future: _buildVideoThumbnail(
                                            messageData['video']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator
                                                .adaptive();
                                          }
                                          if (snapshot.hasData) {
                                            return SizedBox(
                                              width: 150,
                                              height: 150,
                                              child: snapshot.data!,
                                            );
                                          } else {
                                            return const Icon(Icons.error);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                if (messageData['audio'] != null)
                                  Card(
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(_isPlaying &&
                                                    _playingAudioUrl ==
                                                        messageData['audio']
                                                ? Icons.pause
                                                : Icons.play_arrow),
                                            onPressed: () {
                                              if (_isPlaying &&
                                                  _playingAudioUrl ==
                                                      messageData['audio']) {
                                                _pauseAudio();
                                              } else {
                                                playAudio(messageData['audio']);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.stop),
                                            onPressed: () {
                                              if (_isPlaying) stopAudio();
                                            },
                                          ),
                                          Expanded(
                                            child: Slider(
                                              value: _currentPosition.inSeconds
                                                  .toDouble(),
                                              max: _totalDuration.inSeconds
                                                  .toDouble(),
                                              onChanged: (value) {
                                                _audioPlayer.seek(Duration(
                                                    seconds: value.toInt()));
                                                if (mounted) {
                                                  setState(() {
                                                    _currentPosition = Duration(
                                                        seconds: value.toInt());
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            '${_currentPosition.toString().split('.').first} / ${_totalDuration.toString().split('.').first}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Text(
                                  _formatTimestamp(messageData['timestamp']),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
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
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.redAccent,
              child: const Text('Gravando...',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ActionBar(
            isRecording: _isRecording,
            onCameraPressed: () =>
                _sendMedia(fromGallery: false, isVideo: false),
            onGalleryPressed: () =>
                _sendMedia(fromGallery: true, isVideo: false),
            onVideoPressed: () => _sendMedia(fromGallery: false, isVideo: true),
            onRecordPressed: _isRecording ? _stopRecording : _startRecording,
            onSendMessage: _sendMessage,
            messageController: _messageController,
          ),
        ],
      ),
    );
  }
}
