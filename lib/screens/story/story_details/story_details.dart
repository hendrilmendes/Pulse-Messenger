import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social/screens/story/story_view/story_view.dart';
import 'package:video_player/video_player.dart';

class StoryDetailScreen extends StatefulWidget {
  final String userId;

  const StoryDetailScreen({super.key, required this.userId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _stories = [];
  bool _hasError = false;
  String _errorMessage = '';
  VideoPlayerController? _videoPlayerController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchStories();
    _pageController.addListener(_pageControllerListener);
  }

  @override
  void dispose() {
    _disposeVideo();
    _pageController.removeListener(_pageControllerListener);
    _pageController.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  void _pageControllerListener() {
    if (_currentIndex != _pageController.page!.round()) {
      _disposeVideo();
      setState(() {
        _currentIndex = _pageController.page!.round();
      });
    }
  }

  Future<void> _fetchStories() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('stories')
              .where('user_id', isEqualTo: widget.userId)
              .orderBy('created_at', descending: false)
              .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Não foi encontrado momentos desse usuário.';
          });
        }
        return;
      }

      final storyData = querySnapshot.docs.map((doc) => doc.data()).toList();

      if (mounted) {
        setState(() {
          _stories = storyData;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Erro ao carregar as histórias: $e';
        });
      }
    }
  }

  void _showViews(BuildContext context, Map<String, dynamic> story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    width: MediaQuery.of(context).size.width,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: StoryViewsScreen(
                        viewedBy: List<String>.from(story['viewed_by'] ?? []),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _hasError
              ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              )
              : _stories.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : GestureDetector(
                onTapDown: (details) {
                  if (details.globalPosition.dx <
                      MediaQuery.of(context).size.width / 2) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _stories.length,
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        final isVideo = story['media_type'] == 'video';
                        final mediaUrl = story['media_url'] ?? '';

                        if (!isVideo) {
                          _disposeVideo();
                        } else if (_videoPlayerController == null ||
                            !_videoPlayerController!.value.isInitialized) {
                          _disposeVideo();
                          _videoPlayerController =
                              VideoPlayerController.networkUrl(mediaUrl)
                                ..initialize()
                                    .then((_) {
                                      setState(() {});
                                      _videoPlayerController!.play();
                                    })
                                    .catchError((e) {
                                      setState(() {
                                        _hasError = true;
                                        _errorMessage =
                                            'Erro ao carregar vídeo: $e';
                                      });
                                    });
                        }

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            story['media_type'] == 'image'
                                ? CachedNetworkImage(
                                  imageUrl: story['media_url'],
                                  fit: BoxFit.cover,
                                  errorWidget:
                                      (context, url, error) => const Center(
                                        child: Text(
                                          'Falha ao carregar imagem',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                  placeholder:
                                      (context, url) => const Center(
                                        child:
                                            CircularProgressIndicator.adaptive(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                      ),
                                )
                                : story['media_type'] == 'video' &&
                                    _videoPlayerController
                                            ?.value
                                            .isInitialized ==
                                        true
                                ? VideoPlayer(_videoPlayerController!)
                                : const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                            Positioned(
                              top: 60,
                              left: 10,
                              right: 10,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        story['user_photo'].isNotEmpty
                                            ? CachedNetworkImageProvider(
                                              story['user_photo'],
                                            )
                                            : null,
                                    child:
                                        story['user_photo'].isEmpty
                                            ? const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    story['username'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(story['created_at'].toDate()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 10,
                              right: 10,
                              child: Text(
                                story['story_content'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: GestureDetector(
                                onTap: () => _showViews(context, story),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
