import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social/screens/login/login.dart';
import 'package:social/services/auth/auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, size: 28),
            onPressed: () {
              authService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(authService: authService),
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
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
                  children: const [
      
                    ConfigTile(
                        icon: CupertinoIcons.bell,
                      title: 'Notificações',
                    ),
                    ConfigTile(
                      icon: CupertinoIcons.chat_bubble,
                      title: 'Conversas',
                    ),
                    ConfigTile(
                      icon: CupertinoIcons.shield,
                      title: 'Privacidade e Segurança',
                    ),
                    ConfigTile(
                        icon: CupertinoIcons.archivebox,
                      title: 'Armazenamento e Dados',
                    ),
                    ConfigTile(
                      icon: CupertinoIcons.question_circle,
                      title: 'Central de Ajuda',
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
}

class ConfigTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const ConfigTile({super.key, required this.icon, required this.title});

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
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }
}
