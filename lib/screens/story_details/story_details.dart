import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryDetailScreen extends StatefulWidget {
  final String userId;

  const StoryDetailScreen({super.key, required this.userId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _stories = [];
  bool _hasError = false;
  String _errorMessage = '';
  double _progress = 0.0;
  bool _isPaused = false; // Controla o estado de pausa

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
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

      _startAutoPlay();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error fetching stories: $e';
        });
      }
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isPaused) return;

      if (_currentPage < _stories.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
        if (mounted) {
          Navigator.pop(context);
        }
      }
      _resetProgress();
    });
    _startProgress();
  }

  void _startProgress() {
    _progress = 0.0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused) return;
      if (mounted) {
        setState(() {
          _progress += 0.01;
        });
      }
      if (_progress >= 1.0) {
        timer.cancel();
      }
    });
  }

  void _resetProgress() {
    if (mounted) {
      setState(() {
        _progress = 0.0;
      });
    }
    _startProgress();
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _timer?.cancel();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError
          ? Center(
              child: Text(_errorMessage,
                  style: const TextStyle(color: Colors.white)))
          : _stories.isEmpty
              ? const Center(child: CircularProgressIndicator.adaptive())
              : GestureDetector(
                  onLongPress: _pauseStory,
                  onLongPressUp: _resumeStory,
                  onTapDown: (details) {
                    if (!_isPaused) {
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
                      _resetProgress();
                    }
                  },
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                          _resetProgress();
                        },
                        itemCount: _stories.length,
                        itemBuilder: (context, index) {
                          final story = _stories[index];
                          final userPhoto = story['user_photo'] ?? '';
                          final userName = story['username'] ?? 'Unknown';
                          final storyImage = story['image_url'] ?? '';

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              storyImage.isNotEmpty
                                  ? Image.network(
                                      storyImage,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Text(
                                              'Falha ao carregar imagem',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        );
                                      },
                                    )
                                  : Container(color: Colors.black),
                              Positioned(
                                top: 50,
                                left: 10,
                                right: 10,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: userPhoto.isNotEmpty
                                          ? NetworkImage(userPhoto)
                                          : null,
                                      child: userPhoto.isEmpty
                                          ? const Icon(Icons.person,
                                              color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 10,
                                left: 10,
                                right: 10,
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  backgroundColor: Colors.grey.withOpacity(0.5),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
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
