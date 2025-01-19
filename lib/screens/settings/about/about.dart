import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String appVersion = '';
  String appBuild = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        appVersion = packageInfo.version;
        appBuild = packageInfo.buildNumber;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.about,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        children: [
          const SizedBox(height: 20),
          // App Logo Section
          const Center(
            child: Card(
              elevation: 8,
              shape: CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image(
                  image: AssetImage('assets/img/logo.png'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Copyright © Hendril Mendes, 2024-$currentYear',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),
          // App Version and Build Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.version}: $appVersion',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Build: $appBuild',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(),

          // Privacy Policy
          _buildListTile(
            context,
            icon: Icons.shield,
            title: AppLocalizations.of(context)!.privacy,
            onTap: () {
              launchUrl(
                Uri.parse(
                  'https://br-newsdroid.blogspot.com/p/politica-de-privacidade.html',
                ),
                mode: LaunchMode.inAppBrowserView,
              );
            },
          ),

          // Source Code
          _buildListTile(
            context,
            icon: Icons.code,
            title: AppLocalizations.of(context)!.sourceCode,
            onTap: () {
              launchUrl(
                Uri.parse('https://github.com/hendrilmendes/Social/'),
                mode: LaunchMode.inAppBrowserView,
              );
            },
          ),

          // Licenses
          _buildListTile(
            context,
            icon: Icons.folder,
            title: AppLocalizations.of(context)!.openSource,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => LicensePage(
                    applicationName: AppLocalizations.of(context)!.appName,
                  ),
                ),
              );
            },
          ),
        ],
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
