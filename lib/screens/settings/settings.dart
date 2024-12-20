import 'dart:io';
import 'dart:typed_data';
import 'package:app_settings/app_settings.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/auth_provider.dart';
import 'package:social/providers/theme_provider.dart';
import 'package:social/screens/settings/about/about.dart';
import 'package:social/screens/settings/edit_profile/edit_profile.dart';
import 'package:social/screens/settings/language/language.dart';
import 'package:social/screens/settings/privacy/privacy.dart';
import 'package:social/screens/settings/saved_posts/saved_posts.dart';
import 'package:social/screens/settings/theme/theme.dart';

// Função para escrever a imagem no armazenamento
Future<String> writeImageToStorage(Uint8List feedbackScreenshot) async {
  final Directory output = await getTemporaryDirectory();
  final String screenshotFilePath = '${output.path}/feedback.png';
  final File screenshotFile = File(screenshotFilePath);
  await screenshotFile.writeAsBytes(feedbackScreenshot);
  return screenshotFilePath;
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _editProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EditProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () {
              authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.exit_to_app),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // Conta Section
          _buildSectionTitle(AppLocalizations.of(context)!.account),
          _buildListTile(
            context,
            icon: Icons.person,
            title: AppLocalizations.of(context)!.editProfile,
            onTap: () => _editProfile(context, userId!),
          ),
          _buildListTile(
            context,
            icon: Icons.lock,
            title: AppLocalizations.of(context)!.privacy,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const PrivacyScreen(),
                ),
              );
            },
          ),

          _buildListTile(
            context,
            icon: Icons.bookmark,
            title: AppLocalizations.of(context)!.savedPosts,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => SavedPostsScreen(userId: userId ?? 'default_user_id')),
              );
            },
          ),

          const Divider(),

          // Configurações Section
          _buildSectionTitle(AppLocalizations.of(context)!.settings),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: AppLocalizations.of(context)!.notification,
            onTap: () {
              AppSettings.openAppSettings(type: AppSettingsType.notification);
            },
          ),

          _buildListTile(
            context,
            icon: Icons.palette,
            title: AppLocalizations.of(context)!.interface,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ThemeScreen(
                    themeModel: themeModel,
                  ),
                ),
              );
            },
          ),

          _buildListTile(
            context,
            icon: Icons.language,
            title: AppLocalizations.of(context)!.language,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const LanguageScreen(),
                ),
              );
            },
          ),

          const Divider(),

          _buildListTile(
            context,
            icon: Icons.info,
            title: AppLocalizations.of(context)!.about,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),

          _buildListTile(
            context,
            icon: Icons.support,
            title: AppLocalizations.of(context)!.support,
            onTap: () {
              BetterFeedback.of(context).show((feedback) async {
                final screenshotFilePath =
                    await writeImageToStorage(feedback.screenshot);

                final Email email = Email(
                  body: feedback.text,
                  // ignore: use_build_context_synchronously
                  subject: AppLocalizations.of(context)!.appName,
                  recipients: ['hendrilmendes2015@gmail.com'],
                  attachmentPaths: [screenshotFilePath],
                  isHTML: false,
                );
                await FlutterEmailSender.send(email);
              });
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
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
    );
  }
}
