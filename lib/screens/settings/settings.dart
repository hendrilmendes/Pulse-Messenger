import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/auth_provider.dart';
import 'package:social/screens/edit_profile/edit_profile.dart';
import 'package:social/screens/notification/notification.dart';
import 'package:social/screens/settings/privacy/privacy.dart';
import 'package:social/screens/settings/theme/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _editProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Conta Section
          _buildSectionTitle('Conta'),
          _buildListTile(
            context,
            icon: Icons.person,
            title: 'Editar Perfil',
            onTap: () => _editProfile(context, userId!),
          ),
          _buildListTile(
            context,
            icon: Icons.lock,
            title: 'Privacidade',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0), // Espaçamento entre seções

          // Configurações Section
          _buildSectionTitle('Configurações'),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: 'Notificações',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.palette,
            title: 'Tema',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0), // Espaçamento entre seções

          // Logout Section
          _buildListTile(
            context,
            icon: Icons.exit_to_app,
            title: 'Desconectar',
            onTap: () {
              authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 0,
    );
  }
}
