import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:social/providers/theme_provider.dart';

class ThemeScreen extends StatelessWidget {
  final ThemeModel themeModel;

  const ThemeScreen({super.key, required this.themeModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          AppLocalizations.of(context)!.interface,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildSectionTitle(AppLocalizations.of(context)!.theme),
          _buildListTile(
            context,
            icon: Icons.light_mode,
            title: AppLocalizations.of(context)!.lightMode,
            onTap: () {
              themeModel.changeThemeMode(ThemeModeType.light);
            },
          ),
          _buildListTile(
            context,
            icon: Icons.dark_mode,
            title: AppLocalizations.of(context)!.darkMode,
            onTap: () {
              themeModel.changeThemeMode(ThemeModeType.dark);
            },
          ),
          _buildListTile(
            context,
            icon: Icons.settings,
            title: AppLocalizations.of(context)!.systemMode,
            onTap: () {
              themeModel.changeThemeMode(ThemeModeType.system);
            },
          ),
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

  Widget _buildListTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
    );
  }
}
