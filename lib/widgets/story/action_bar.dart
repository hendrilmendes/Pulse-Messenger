import 'package:flutter/material.dart';

class StoryActionBar extends StatefulWidget {
  final TextEditingController storyController;
  final void Function() onPickImage;
  final void Function() onUploadStory;

  const StoryActionBar({
    super.key,
    required this.storyController,
    required this.onPickImage,
    required this.onUploadStory,
  });

  @override
  // ignore: library_private_types_in_public_api
  _StoryActionBarState createState() => _StoryActionBarState();
}

class _StoryActionBarState extends State<StoryActionBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: widget.storyController,
                decoration: InputDecoration(
                  hintText: 'O que está pensando?',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blue),
            onPressed: widget.onPickImage,
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: widget.onUploadStory,
          ),
        ],
      ),
    );
  }
}
