import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StoryActionBar extends StatefulWidget {
  final void Function() onPickImage;
  final void Function() onPickVideo;
  final void Function() onUploadStory;
  final TextEditingController storyController;

  const StoryActionBar({
    super.key,
    required this.storyController,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onUploadStory,
  });

  @override
  // ignore: library_private_types_in_public_api
  _StoryActionBarState createState() => _StoryActionBarState();
}

class _StoryActionBarState extends State<StoryActionBar> {
  void _showActionModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Escolher uma Imagem'),
                onTap: widget.onPickImage,
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blue),
                title: const Text('Escolher um Vídeo'),
                onTap: widget.onPickVideo,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.blue),
                onPressed: _showActionModal, // Abre o modal com as opções
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: widget.storyController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.hintTextMomment,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: widget.onUploadStory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
