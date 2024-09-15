import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class ConversationDetailsScreen extends StatelessWidget {
  final String chatId;
  final String userId;

  const ConversationDetailsScreen({
    super.key,
    required this.chatId,
    required this.userId,
  });

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _fetchMedia() async {
    try {
      QuerySnapshot messagesDocs = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      if (kDebugMode) {
        print('Queried documents count: ${messagesDocs.docs.length}');
      }

      List<Map<String, dynamic>> mediaList = messagesDocs.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (kDebugMode) {
              print('Document data: $data');
            }

            if (data.containsKey('audio') && data['audio'] != null) {
              return {'type': 'audio', 'url': data['audio']};
            } else if (data.containsKey('image') && data['image'] != null) {
              return {'type': 'image', 'url': data['image']};
            } else if (data.containsKey('video') && data['video'] != null) {
              return {'type': 'video', 'url': data['video']};
            } else if (data.containsKey('document') &&
                data['document'] != null) {
              return {'type': 'document', 'url': data['document']};
            } else {
              return null;
            }
          })
          .where((data) => data != null)
          .cast<Map<String, dynamic>>()
          .toList();

      if (kDebugMode) {
        print('Filtered media: $mediaList');
      }
      return mediaList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching media: $e');
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes da Conversa',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: FutureBuilder(
        future: Future.wait([_fetchUserData(), _fetchMedia()]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nenhum dado disponível.'));
          }

          Map<String, dynamic> userData = snapshot.data![0];
          List<Map<String, dynamic>> mediaList = snapshot.data![1];

          List<Map<String, dynamic>> images =
              mediaList.where((media) => media['type'] == 'image').toList();
          List<Map<String, dynamic>> audios =
              mediaList.where((media) => media['type'] == 'audio').toList();
          List<Map<String, dynamic>> videos =
              mediaList.where((media) => media['type'] == 'video').toList();
          List<Map<String, dynamic>> documents =
              mediaList.where((media) => media['type'] == 'document').toList();

          bool hasMedia = images.isNotEmpty ||
              audios.isNotEmpty ||
              videos.isNotEmpty ||
              documents.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                            userData['profile_picture'] ??
                                'https://example.com/default-pic.jpg'),
                        radius: 30,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['username'] ?? 'User Name',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['bio'] ?? 'Bio',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {
                          // Add your block functionality here
                        },
                        child: const Text('Bloquear Usuário'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {
                          // Add your mute functionality here
                        },
                        child: const Text('Silenciar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasMedia) ...[
                  if (images.isNotEmpty) ...[
                    const Text('Imagens',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: images.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        var media = images[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => FullScreenImageView(
                                  imageUrl: media['url'],
                                ),
                              ),
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl: media['url'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        );
                      },
                    ),
                  ],
                  if (videos.isNotEmpty) ...[
                    const Divider(thickness: 1, color: Colors.grey),
                    const Text('Vídeos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        var media = videos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.video_library),
                            title: Text('Vídeo ${index + 1}'),
                            subtitle: CachedNetworkImage(
                              imageUrl: media['url'],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => FullScreenVideoPlayer(
                                    videoUrl: media['url'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                  if (documents.isNotEmpty) ...[
                    const Divider(thickness: 1, color: Colors.grey),
                    const Text('Documentos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.document_scanner),
                            title: Text('Documento ${index + 1}'),
                            subtitle: const Text('Clique para abrir'),
                            onTap: () {
                              // Handle media tap, e.g., open document
                            },
                          ),
                        );
                      },
                    ),
                  ],
                  if (audios.isNotEmpty) ...[
                    const Divider(thickness: 1, color: Colors.grey),
                    const Text('Áudios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: audios.length,
                      itemBuilder: (context, index) {
                        var media = audios[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.audio_file),
                            title: const Text('Áudio'),
                            subtitle: const Text('Clique para ouvir'),
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => FullScreenAudioPlayer(
                                    audioUrl: media['url'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ] else ...[
                  const Center(
                    child: Text('Nenhuma mídia disponível',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  // ignore: library_private_types_in_public_api
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vídeo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class FullScreenAudioPlayer extends StatefulWidget {
  final String audioUrl;

  const FullScreenAudioPlayer({super.key, required this.audioUrl});

  @override
  // ignore: library_private_types_in_public_api
  _FullScreenAudioPlayerState createState() => _FullScreenAudioPlayerState();
}

class _FullScreenAudioPlayerState extends State<FullScreenAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
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
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _seekTo(double value) async {
    final position = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Áudio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 64,
              ),
              onPressed: _togglePlayPause,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      Slider(
                        value: _currentPosition.inMilliseconds.toDouble(),
                        max: _totalDuration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _seekTo(value);
                        },
                      ),
                      Text(
                        '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                      ),
                    ],
                  ),
            Text(_isPlaying ? 'Tocando...' : 'Pausado'),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
