import 'package:flutter/material.dart';
import 'package:social/l10n/app_localizations.dart';

class ActionBar extends StatefulWidget {
  final bool isRecording;
  final void Function() onCameraPressed;
  final void Function() onGalleryPressed;
  final void Function() onVideoPressed;
  final void Function() onRecordPressed;
  final void Function(String) onSendMessage;
  final TextEditingController messageController;

  const ActionBar({
    super.key,
    required this.isRecording,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onVideoPressed,
    required this.onRecordPressed,
    required this.onSendMessage,
    required this.messageController,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ActionBarState createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
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
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tirar uma Foto'),
                onTap: widget.onCameraPressed,
              ),
              ListTile(
                leading: const Icon(Icons.video_call, color: Colors.blue),
                title: const Text('Gravar um Vídeo'),
                onTap: widget.onVideoPressed,
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Escolher da Galeria'),
                onTap: widget.onGalleryPressed,
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
                onPressed: _showActionModal,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: widget.messageController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.hintText,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        widget.onSendMessage(text);
                        widget.messageController.clear();
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.messageController.text.isNotEmpty
                      ? Icons.send
                      : (widget.isRecording ? Icons.stop : Icons.mic),
                  color:
                      widget.messageController.text.isNotEmpty
                          ? Colors.blue
                          : (widget.isRecording ? Colors.red : Colors.blue),
                ),
                onPressed: () {
                  if (widget.messageController.text.isNotEmpty) {
                    widget.onSendMessage(widget.messageController.text);
                    widget.messageController.clear();
                  } else {
                    widget.onRecordPressed();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
