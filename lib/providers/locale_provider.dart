import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Locale? get locale => _locale;

  // Método para definir o idioma selecionado pelo usuário
  void setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    // Salvar o idioma escolhido no SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  // Método para limpar o idioma manualmente definido (voltar ao idioma do dispositivo)
  void clearLocale() async {
    _locale = null;
    notifyListeners();

    // Remover o idioma escolhido do SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('locale');
  }

  // Método para carregar o idioma salvo ou usar o do dispositivo
  void _loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('locale');

    if (languageCode != null) {
      _locale = Locale(languageCode); // Se o usuário escolheu um idioma, use-o
    } else {
      // Use o idioma do dispositivo como padrão
      _locale = PlatformDispatcher.instance.locale;
    }

    notifyListeners();
  }
}
