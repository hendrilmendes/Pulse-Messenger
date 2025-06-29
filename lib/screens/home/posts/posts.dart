import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:social/widgets/avatar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedFile;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  static const int maxChars = 280;

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file != null) {
        setState(() => _selectedFile = file);
        return;
      }

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (video != null) {
        setState(() => _selectedFile = video);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar mídia: $e')));
    }
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();

    if (caption.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite algo para postar.')));
      return;
    }

    setState(() => _isSubmitting = true);

    final uri = Uri.parse('https://social.hendrilmendes2015.workers.dev/api/posts');

    final request = http.MultipartRequest('POST', uri)
      ..fields['author'] = 'Hendril Mendes'
      ..fields['username'] = '@hendrilmendes'
      ..fields['time'] = 'agora'
      ..fields['caption'] = caption
      ..fields['reactions'] = '0'
      ..fields['comments'] = '0'
      ..fields['avatar'] = 'https://i.imgur.com/BoN9kdC.png';

    if (_selectedFile != null) {
      final fileBytes = await _selectedFile!.readAsBytes();
      final file = http.MultipartFile.fromBytes(
        'media', // o campo esperado pelo backend
        fileBytes,
        filename: _selectedFile!.name,
      );
      request.files.add(file);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao postar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charsLeft = maxChars - _captionController.text.length;
    final isOverLimit = charsLeft < 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Post')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const UserAvatar(radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      maxLength: maxChars,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Compartilhe algo...",
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedFile!.path),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFile = null),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _pickImage,
                    tooltip: 'Inserir imagem ou vídeo',
                  ),
                  Text(
                    '$charsLeft',
                    style: TextStyle(
                      fontSize: 14,
                      color: isOverLimit ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text("Publicar"),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        (_isSubmitting ||
                            isOverLimit ||
                            _captionController.text.trim().isEmpty)
                        ? Colors.grey
                        : theme.colorScheme.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      (_isSubmitting ||
                          isOverLimit ||
                          _captionController.text.trim().isEmpty)
                      ? null
                      : _submitPost,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
