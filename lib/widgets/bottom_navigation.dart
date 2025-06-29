import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social/screens/chat/chat.dart';
import 'package:social/screens/home/home.dart';
import 'package:social/screens/status/status.dart';
import 'package:social/screens/more/more.dart';
import 'package:social/widgets/avatar.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Adiciona listener para mudanças no usuário
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  final List<Widget> _screens = [
    HomeScreen(),
    StatusScreen(),
    ChatScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 65,
          indicatorColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(CupertinoIcons.house),
              selectedIcon: const Icon(CupertinoIcons.house_fill),
              label: "Inicio",
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.memories),
              label: "Momentos",
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.chat_bubble),
              selectedIcon: const Icon(CupertinoIcons.chat_bubble_fill),
              label: "Conversas",
            ),
            NavigationDestination(
              icon: UserAvatar(
                radius: 14,
                photoUrl: _currentUser?.photoURL,
                displayName: _currentUser?.displayName,
              ),
              label: "Mais",
            ),
          ],
        ),
      ),
    );
  }
}
