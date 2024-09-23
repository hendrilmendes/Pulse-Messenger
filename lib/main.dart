import 'package:feedback/feedback.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:social/providers/locale_provider.dart';
import 'package:social/providers/theme_provider.dart';
import 'package:social/screens/chat/chat.dart';
import 'package:social/screens/comments/comments.dart';
import 'package:social/screens/home/home.dart';
import 'package:social/screens/login/login.dart';
import 'package:social/services/notification.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.init();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!
      .requestNotificationsPermission();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return BetterFeedback(
            theme: FeedbackThemeData.light(),
            darkTheme: FeedbackThemeData.dark(),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalFeedbackLocalizationsDelegate(),
            ],
            localeOverride: localeProvider.locale,
            child: const MyApp(),
          );
        },
      ),
    ),
  );
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<ThemeModel>(
          create: (_) => ThemeModel(),
        ),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(),
        ),
      ],
      child: Consumer3<ThemeModel, LocaleProvider, AuthProvider>(
        builder: (_, themeModel, localeProvider, authProvider, __) {
          return MaterialApp(
              theme: ThemeData(
                brightness: Brightness.light,
                useMaterial3: true,
                textTheme: Typography()
                    .black
                    .apply(fontFamily: GoogleFonts.robotoFlex().fontFamily),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                textTheme: Typography()
                    .white
                    .apply(fontFamily: GoogleFonts.robotoFlex().fontFamily),
              ),
              themeMode: _getThemeMode(themeModel.themeMode),
              locale: localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              debugShowCheckedModeBanner: false,
              home: const AuthWrapper(),
              onGenerateRoute: (RouteSettings settings) {
                final args = settings.arguments as Map<String, dynamic>?;

                switch (settings.name) {
                  case '/home':
                    return CupertinoPageRoute(
                        builder: (_) => const HomeScreen());
                  case '/login':
                    return CupertinoPageRoute(builder: (_) => LoginScreen());
                  case '/chat':
                    return CupertinoPageRoute(
                        builder: (_) => const ChatsScreen());
                  case '/comments':
                    final postId = args?['postId'] as String?;
                    final postOwnerId = args?['postOwnerId'] as String?;
                    if (postId != null && postOwnerId != null) {
                      return CupertinoPageRoute(
                        builder: (_) => CommentsScreen(
                            postId: postId, postOwnerId: postOwnerId),
                      );
                    }
                    return CupertinoPageRoute(
                        builder: (_) => const HomeScreen());
                  default:
                    return CupertinoPageRoute(
                        builder: (_) => const HomeScreen());
                }
              });
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}
