import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  Future<Uint8List?>? _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
    _thumbnailFuture = _generateThumbnail(widget.url);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<Uint8List?> _generateThumbnail(String videoUrl) async {
    final uint8List = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 75,
    );
    return uint8List;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_controller != null && _controller!.value.isInitialized)
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          )
        else
          const Center(child: CircularProgressIndicator.adaptive()),
        FutureBuilder<Uint8List?>(
          future: _thumbnailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
            onPressed: () {
              if (_controller != null && _controller!.value.isInitialized) {
                _controller!.play();
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }
}
