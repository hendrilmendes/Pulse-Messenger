import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale = const Locale('pt');

  Locale? get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    notifyListeners();
  }
}
