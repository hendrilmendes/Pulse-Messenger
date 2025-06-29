import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social/services/auth/auth.dart';
import 'package:social/widgets/bottom_navigation.dart';
import 'package:social/firebase_options.dart';
import 'package:social/l10n/app_localizations.dart';
import 'package:social/screens/login/login.dart';
import 'package:social/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

ThemeMode _getThemeMode(ThemeModeType mode) {
  switch (mode) {
    case ThemeModeType.light:
      return ThemeMode.light;
    case ThemeModeType.dark:
      return ThemeMode.dark;
    case ThemeModeType.system:
      return ThemeMode.system;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (context) => AuthService()),
        ChangeNotifierProvider<ThemeModel>(create: (_) => ThemeModel()),
      ],
      child: Consumer<ThemeModel>(
        builder: (_, themeModel, _) {
          return MaterialApp(
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: _getThemeMode(themeModel.themeMode),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _buildHome(authService),
          );
        },
      ),
    );
  }
}

Widget _buildHome(AuthService authService) {
  return FutureBuilder<User?>(
    future: authService.currentUser(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasData) {
          return const BottomNav();
        } else {
          return LoginScreen(authService: authService);
        }
      } else {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        );
      }
    },
  );
}
