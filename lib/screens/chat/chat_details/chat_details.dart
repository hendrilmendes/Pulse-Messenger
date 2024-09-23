import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social/providers/manager_audio.dart';
import 'dart:io';
import 'package:social/screens/call/call.dart';
import 'package:social/screens/chat/conversation_details/conversation_details.dart';
import 'package:social/screens/call/video_call/video_call.dart';
import 'package:social/services/presense.dart';
import 'package:social/widgets/chat/action_bar.dart';
import 'package:social/widgets/chat/audio.dart';
import 'package:social/widgets/chat/full_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const ChatDetailScreen({
    required this.chatId,
    required this.userId,
    super.key,
    required bool isGroup,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _record = AudioRecorder();
  bool _isRecording = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late Stream<QuerySnapshot> _messagesStream;
  Map<String, String>? _userData;
  bool isPlaying = false;
  bool isPaused = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  String? playingAudioUrl;
  bool _isConversationOpen = false;
  bool isTyping = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late PresenceService _presenceService;

  @override
  void initState() {
    super.initState();
    _presenceService = PresenceService();
    _presenceService.updateUserStatus('online');
    _updateTypingStatus(false);

    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();

    _loadUserData();

    // Listen for new messages
    _messagesStream.listen((querySnapshot) {
      if (_isConversationOpen) {
        for (var doc in querySnapshot.docs) {
          _checkAndMarkMessagesAsRead(doc.id);
        }
      }
    });

    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        setState(() {
          isTyping = true;
        });
        _updateTypingStatus(true);
        _presenceService.updateUserStatus('typing');
      } else {
        setState(() {
          isTyping = false;
        });
        _updateTypingStatus(false);
        _presenceService.updateUserStatus('online');
      }
    });

    // Set the conversation as open
    _isConversationOpen = true;

    // Marcar todas as mensagens como lidas quando a conversa for aberta
    if (_isConversationOpen) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          _checkAndMarkMessagesAsRead(doc.id);
        }
      });
    }

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
          isPaused = state == PlayerState.paused;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    _presenceService.updateUserStatus('offline');
    _messageController.removeListener(() {});
    _audioPlayer.dispose();
    _isConversationOpen = false;
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentUserId = _auth.currentUser!.uid;

    try {
      // Adiciona a mensagem à coleção de mensagens no Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': text,
        'sender_id': currentUserId,
        'timestamp': Timestamp.now(),
        'read': false,
      });

      // Atualiza o documento do chat com a última mensagem e hora
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': text,
        'last_message_time': Timestamp.now(),
      });

      // Obtém o documento do chat para atualizar o unread_count dos outros participantes
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);

      // Atualiza o unread_count apenas para os participantes que não são o remetente
      for (String participantId in participants) {
        if (participantId != currentUserId) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .update({
            'unread_count.$participantId': FieldValue.increment(1),
          });
        }
      }

      // Limpa o campo de texto da mensagem
      _messageController.clear();
    } catch (e) {
      // Exibe um erro caso ocorra algum problema
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _sendAudio(File audioFile) async {
    final currentUserId = _auth.currentUser!.uid;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audios/${DateTime.now().millisecondsSinceEpoch}.m4a');
      final uploadTask = storageRef.putFile(audioFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Adiciona a mensagem de áudio à coleção de mensagens no Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'audio': downloadUrl,
        'sender_id': currentUserId,
        'timestamp': Timestamp.now(),
        'read': false,
      });

      // Atualiza o documento do chat com a última mensagem e hora
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': 'Mensagem de Áudio',
        'last_message_time': Timestamp.now(),
      });

      // Obtém o documento do chat para atualizar o unread_count dos outros participantes
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);

      // Atualiza o unread_count apenas para os participantes que não são o remetente
      for (String participantId in participants) {
        if (participantId != currentUserId) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .update({
            'unread_count.$participantId': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      // Exibe um erro caso ocorra algum problema
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

  Future<void> _sendMedia(
      {required bool fromGallery, bool isVideo = false}) async {
    final currentUserId = _auth.currentUser!.uid;

    try {
      File? file;
      bool isVideoFile = false;

      if (fromGallery) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.media,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          file = File(result.files.first.path!);
          isVideoFile = result.files.first.extension == 'mp4' ||
              result.files.first.extension == 'mov';
        } else {
          throw 'Nenhuma mídia selecionada';
        }
      } else {
        final ImagePicker picker = ImagePicker();
        XFile? pickedFile;

        if (isVideo) {
          pickedFile = await picker.pickVideo(source: ImageSource.camera);
        } else {
          pickedFile = await picker.pickImage(
              source: ImageSource.camera, imageQuality: 100);
        }

        if (pickedFile != null) {
          file = File(pickedFile.path);
          isVideoFile = pickedFile.mimeType?.startsWith('video') ?? false;
        } else {
          throw 'Nenhuma mídia capturada';
        }
      }

      // Carregar o arquivo no Firebase Storage
      final fileExtension = file.path.split('.').last;
      final storageRef = FirebaseStorage.instance.ref().child(
          '${isVideoFile ? 'videos' : 'images'}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Adiciona a mensagem com a URL da mídia à coleção de mensagens no Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        isVideoFile ? 'video' : 'image': downloadUrl,
        'sender_id': currentUserId,
        'timestamp': Timestamp.now(),
        'read': false,
      });

      // Atualiza o documento do chat com a última mensagem e hora
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'last_message': isVideoFile ? 'Vídeo' : 'Imagem',
        'last_message_time': Timestamp.now(),
      });

      // Obtém o documento do chat para atualizar o unread_count dos outros participantes
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);

      // Atualiza o unread_count apenas para os participantes que não são o remetente
      for (String participantId in participants) {
        if (participantId != currentUserId) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .update({
            'unread_count.$participantId': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration =
            Duration(seconds: _recordingDuration.inSeconds + 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formattedDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _startRecording() async {
    if (await _record.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Configuração de alta qualidade
      const recordConfig = RecordConfig(
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _record.start(recordConfig, path: path);
      _startTimer(); // Inicia o temporizador

      if (mounted) {
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de gravação negada')),
      );
    }
  }

  void _stopRecording() async {
    final filePath = await _record.stop();
    _stopTimer(); // Para o temporizador

    if (filePath != null) {
      final file = File(filePath);
      await _sendAudio(file);
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero; // Reseta o temporizador
      });
    }
  }

  void playAudio(String audioUrl) {
    AudioManager().playAudio(audioUrl);
  }

  void _pauseAudio(String audioUrl) async {
    AudioManager().pauseAudio(audioUrl);
  }

  void _callScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(
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
      CupertinoPageRoute(
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
          lastSeen != null ? _formatTimes(lastSeen) : 'Unknown';

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

  String _formatTimes(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
  }

  String _formatTimesChat(Timestamp timestamp) {
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  Future<Widget> _buildVideoThumbnail(String videoUrl) async {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 512, // Tamanho máximo da largura da miniatura
      quality: 100,
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

  void markMessageAsRead(String messageId) {
    final userId = _auth.currentUser!.uid;

    if (_isConversationOpen) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .get()
          .then((doc) {
        if (doc.exists) {
          final messageData = doc.data() as Map<String, dynamic>;
          final senderId = messageData['sender_id'];

          // Marca a mensagem como lida somente se não for do próprio usuário
          if (senderId != userId) {
            doc.reference.update({'read': true});
          }
        }
      });
    }
  }

  void _checkAndMarkMessagesAsRead(String messageId) {
    final userId = _auth.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final messageData = doc.data() as Map<String, dynamic>;
        final senderId = messageData['sender_id'];

        // Marca a mensagem como lida somente se não for do próprio usuário
        if (senderId != userId && !(messageData['read'] ?? false)) {
          doc.reference.update({'read': true});
        }
      }
    });
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    final userId = _auth.currentUser!.uid;
    final chatId = widget.chatId;

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'typing_status_$userId': isTyping,
    });
  }

  String formatTimestamp(DateTime? date) {
    if (date == null) {
      return 'Desconhecido';
    }

    final now = DateTime.now().toLocal();
    final localDate = date.toLocal();
    final difference = now.difference(localDate);

    final timeFormat = DateFormat('HH:mm');

    if (difference.inDays == 0) {
      return 'Hoje às ${timeFormat.format(localDate)}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${timeFormat.format(localDate)}';
    } else {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return 'Visto há ${difference.inDays} dias (${dateFormat.format(localDate)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ConversationDetailsScreen(
                  chatId: widget.chatId,
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
                radius: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?['username'] ?? 'Unknown User',
                      style: const TextStyle(fontSize: 18),
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final chatData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final userId = _auth.currentUser!.uid;
                          final participants =
                              chatData['participants'] as List<dynamic>;

                          // Get the other user ID
                          final otherUserId =
                              participants.firstWhere((id) => id != userId);

                          // Check if the other user is typing
                          bool isOtherUserTyping =
                              chatData['typing_status_$otherUserId'] ?? false;

                          // Extract last_seen safely
                          var lastSeenData = _userData?['last_seen'];

                          DateTime? lastSeen;
                          if (lastSeenData is Timestamp) {
                            lastSeen = (lastSeenData as Timestamp).toDate();
                          } else if (lastSeenData is String) {
                            try {
                              final format = DateFormat('dd MMM yyyy, HH:mm');
                              lastSeen = format.parse(lastSeenData);
                            } catch (e) {
                              if (kDebugMode) {
                                print('Error parsing date: $e');
                              }
                              lastSeen =
                                  null; // Handle parse error if necessary
                            }
                          }

                          return AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                _userData?['status'] == 'online'
                                    ? isOtherUserTyping
                                        ? 'Digitando...'
                                        : 'Online'
                                    : 'Última vez visto: ${formatTimestamp(lastSeen)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return const Text('Offline',
                            style: TextStyle(fontSize: 12, color: Colors.grey));
                      },
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
                    final isRead = messageData['read'] ?? false;

                    // Marcar como lida apenas se o usuário atual for o destinatário
                    if (!isMe && !isRead) {
                      _checkAndMarkMessagesAsRead(messageDoc.id);
                    }

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
                                          } else if (snapshot.hasData) {
                                            return snapshot.data!;
                                          } else if (snapshot.hasError) {
                                            return const Icon(Icons.error);
                                          } else {
                                            return const Icon(
                                                Icons.video_library);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                if (messageData['audio'] != null)
                                  AudioCard(
                                    audioUrl: messageData['audio'],
                                    onPlayPausePressed: () {
                                      final isPlayingNotifier = AudioManager()
                                          .getIsPlayingNotifier(
                                              messageData['audio']);

                                      // Check if the audio is currently playing
                                      if (isPlayingNotifier.value) {
                                        _pauseAudio(messageData['audio']);
                                      } else {
                                        playAudio(messageData['audio']);
                                      }
                                    },
                                    onSliderChanged: (value) {
                                      AudioManager().seek(messageData['audio'],
                                          Duration(seconds: value.toInt()));
                                      if (mounted) {
                                        setState(() {
                                          currentPosition =
                                              Duration(seconds: value.toInt());
                                        });
                                      }
                                    },
                                  ),
                                if (isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: isRead
                                        ? const Stack(
                                            children: [
                                              Icon(Icons.check,
                                                  color: Colors.blue, size: 18),
                                              Positioned(
                                                left: 5,
                                                child: Icon(Icons.check,
                                                    color: Colors.blue,
                                                    size: 18),
                                              ),
                                            ],
                                          )
                                        : const Stack(
                                            children: [
                                              Icon(Icons.check,
                                                  color: Colors.grey, size: 18),
                                              Positioned(
                                                left: 5,
                                                child: Icon(Icons.check,
                                                    color: Colors.grey,
                                                    size: 18),
                                              ),
                                            ],
                                          ),
                                  ),
                                Text(
                                  _formatTimesChat(messageData['timestamp']),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Gravando... ${_formattedDuration(_recordingDuration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ActionBar(
            isRecording: _isRecording,
            onCameraPressed: () =>
                _sendMedia(fromGallery: false, isVideo: false),
            onGalleryPressed: () => _sendMedia(fromGallery: true),
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
