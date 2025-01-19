import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/locale_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        Locale? currentLocale =
            localeProvider.locale ?? Localizations.localeOf(context);
        String currentLanguage = _getLanguageName(currentLocale.languageCode);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.language,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            children: [
              _buildLanguageOption(
                  context, 'Português', Icons.language, 'pt', currentLanguage),
              _buildLanguageOption(
                  context, 'Español', Icons.language, 'es', currentLanguage),
              _buildLanguageOption(
                  context, 'English', Icons.language, 'en', currentLanguage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String title, IconData icon,
      String localeCode, String currentLanguage) {
    bool isSelected = currentLanguage == title;

    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
      ),
      onTap: () {
        if (!isSelected) {
          _updateLanguage(context, localeCode);
        }
      },
      trailing: isSelected
          ? const Icon(
              Icons.check,
              color: Colors.blue,
            )
          : null,
    );
  }

  void _updateLanguage(BuildContext context, String localeCode) {
    Provider.of<LocaleProvider>(context, listen: false)
        .setLocale(Locale(localeCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${AppLocalizations.of(context)!.noResult} ${_getLanguageName(localeCode)}'),
      ),
    );
  }

  String _getLanguageName(String localeCode) {
    switch (localeCode) {
      case 'pt':
        return 'Português';
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Português';
    }
  }
}
