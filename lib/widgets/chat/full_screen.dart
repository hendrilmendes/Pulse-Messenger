import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social/widgets/video/video_player.dart';
import 'package:video_player/video_player.dart';

class FullScreenMedia extends StatelessWidget {
  final String url;
  final bool isVideo;

  const FullScreenMedia({super.key, required this.url, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<Widget>(
            future: _buildMediaWidget(context, url, isVideo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasData) {
                return Center(child: snapshot.data!);
              } else {
                return const Center(
                  child: Icon(Icons.error, color: Colors.white),
                );
              }
            },
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildMediaWidget(
    BuildContext context,
    String url,
    bool isVideo,
  ) async {
    if (isVideo) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      return VideoPlayerWidget(url: url);
    } else {
      return CachedNetworkImage(
        imageUrl: url,
        placeholder:
            (context, url) => const CircularProgressIndicator.adaptive(),
        errorWidget:
            (context, url, error) =>
                const Icon(Icons.error, color: Colors.white),
        fit: BoxFit.contain,
      );
    }
  }
}
