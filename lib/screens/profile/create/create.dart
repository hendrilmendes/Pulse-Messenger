import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/services/auth/auth.dart';
import 'package:social/widgets/avatar.dart';
import 'package:social/widgets/bottom_navigation.dart';

class CompleteProfileScreen extends StatefulWidget {
  final AuthService authService;
  final User user;

  const CompleteProfileScreen({
    required this.authService,
    required this.user,
    super.key,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty || username.length < 4) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Mínimo 4 caracteres';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Use apenas letras, números e _';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await widget.authService.checkUsernameAvailability(
        username,
      );

      setState(() {
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Nome já em uso';
      });
    } catch (e) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = e.toString();
      });
    } finally {
      setState(() => _isCheckingUsername = false);
    }
  }

  Future<void> _completeProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira seu nome completo')),
      );
      return;
    }

    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um nome de usuário')),
      );
      return;
    }

    if (!_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha outro nome de usuário')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Atualiza no Firebase e no backend
      await widget.authService.completeUserProfile(
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao completar perfil: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.user.photoURL;
    final displayName = widget.user.displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Stack(
              children: [
                UserAvatar(
                  photoUrl: photoUrl,
                  displayName: displayName,
                  radius: 60,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidade de adicionar foto ainda não implementada',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Nome de Usuário',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: _isCheckingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                errorText: _usernameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onChanged: (value) {
                if (value.length > 3) {
                  _checkUsernameAvailability();
                } else {
                  setState(() {
                    _isUsernameAvailable = false;
                    _usernameError = 'Mínimo 4 caracteres';
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            if (_usernameController.text.isNotEmpty && !_isCheckingUsername)
              Text(
                _isUsernameAvailable ? '✔ Disponível' : '✖ Indisponível',
                style: TextStyle(
                  color: _isUsernameAvailable ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUsernameAvailable
                      ? Colors.blueAccent
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isSubmitting || !_isUsernameAvailable
                    ? null
                    : _completeProfile,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
