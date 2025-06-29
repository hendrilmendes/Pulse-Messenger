import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeType { light, dark, system }

class ThemeModel extends ChangeNotifier {
  bool _isDarkMode = true;
  ThemeModeType _themeMode = ThemeModeType.system;
  SharedPreferences? _prefs;

  ThemeModel() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeModeType get themeMode => _themeMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveThemeModePreference(
      _isDarkMode ? ThemeModeType.dark : ThemeModeType.light,
    );
    notifyListeners();
  }

  void changeThemeMode(ThemeModeType mode) {
    _themeMode = mode;
    _saveThemeModePreference(mode);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeModel.getLightTheme();
  }

  ThemeData get darkTheme {
    return ThemeModel.getDarkTheme();
  }

  Future<void> _loadThemePreference() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('darkModeEnabled') ?? false;
    _themeMode = _getSavedThemeMode(
      _prefs?.getString('themeMode') ?? ThemeModeType.system.toString(),
    );

    notifyListeners();
  }

  Future<void> _saveThemeModePreference(ThemeModeType mode) async {
    await _prefs?.setString('themeMode', mode.toString());
    await _prefs?.setBool('darkModeEnabled', mode == ThemeModeType.dark);
  }

  ThemeModeType _getSavedThemeMode(String mode) {
    switch (mode) {
      case 'ThemeModeType.light':
        return ThemeModeType.light;
      case 'ThemeModeType.dark':
        return ThemeModeType.dark;
      case 'ThemeModeType.system':
        return ThemeModeType.system;
      default:
        return ThemeModeType.system;
    }
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(),
      scaffoldBackgroundColor: Colors.white,
      textTheme: Typography().black.apply(
        fontFamily: GoogleFonts.openSans().fontFamily,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        enableFeedback: true,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(backgroundColor: Colors.black),
      textTheme: Typography().white.apply(
        fontFamily: GoogleFonts.openSans().fontFamily,
      ),
      bottomAppBarTheme: BottomAppBarTheme(color: Colors.black),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
      ),
    );
  }
}
