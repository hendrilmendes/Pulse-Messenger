import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          AppLocalizations.of(context)!.notification,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Notifications Section
          _buildSectionTitle('Notificações Push'),
          _buildSwitchTile(context,
              icon: Icons.notifications,
              title: 'Ativar Notificações',
              isActive: true),
          _buildSwitchTile(context,
              icon: Icons.person_add,
              title: 'Novos Seguidores',
              isActive: true),
          _buildSwitchTile(context,
              icon: Icons.comment,
              title: 'Comentários',
              isActive: false),

          // Other Notifications Section
          _buildSectionTitle('Outras Notificações'),
          _buildSwitchTile(context,
              icon: Icons.favorite_border, title: 'Curtidas', isActive: true),
          _buildSwitchTile(context,
              icon: Icons.message,
              title: 'Mensagens Diretas',
              isActive: false),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context,
      {required IconData icon, required String title, required bool isActive}) {
    return SwitchListTile(
      activeColor: Colors.blueAccent,
      value: isActive,
      onChanged: (bool value) {
        // Handle the toggle switch logic here
      },
      title: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
