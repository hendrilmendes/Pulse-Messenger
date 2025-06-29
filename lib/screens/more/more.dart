import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social/screens/profile/profile.dart';
import 'package:social/screens/settings/settings.dart';
import 'package:social/screens/testimonial/testimonial.dart';
import 'package:social/services/auth/auth.dart';
import 'package:social/widgets/avatar.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final AuthService authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _openTestimonial(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TestimonialsScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await authService.getUserProfileData();
      setState(() {
        userData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar dados do perfil';
      });
      if (kDebugMode) print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuário';
    final username = userData?['username'] != null
        ? '@${userData!['username']}'
        : (user?.email != null ? '@${user!.email!.split('@')[0]}' : '@usuário');
    final photoUrl = user?.photoURL;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com título e QR code
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Perfil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.qr_code, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Foto de perfil com botão de editar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Stack(
                    children: [
                      UserAvatar(
                        photoUrl: photoUrl,
                        displayName: displayName,
                        radius: 38,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _openProfile(context),
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
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        username,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: _getFriendsCount(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text("$count Amigos");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Lista de opções
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF121212)
                      : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    ConfigTile(
                      icon: CupertinoIcons.person,
                      title: 'Perfil',
                      onTap: () => _openProfile(context),
                    ),
                    ConfigTile(
                      icon: CupertinoIcons.chat_bubble_text,
                      title: 'Depoimentos',
                      onTap: () => _openTestimonial(context),
                    ),
                    ConfigTile(
                      icon: CupertinoIcons.settings,
                      title: 'Ajustes',
                      onTap: () => _openSettings(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getFriendsCount() async {
    if (userData != null && userData!.containsKey('friendsCount')) {
      return userData!['friendsCount'] ?? 0;
    }
    return 0;
  }
}

class ConfigTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ConfigTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }
}
