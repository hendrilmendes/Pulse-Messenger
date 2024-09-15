import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/screens/chat/chat.dart';
import 'package:social/screens/feed/feed.dart';
import 'package:social/screens/notification/notification.dart';
import 'package:social/screens/profile/profile.dart';
import 'package:social/screens/search/search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late String currentUserId;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  Future<void> _initializePages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      setState(() {
        _pages.add(FeedScreen(currentUserId: currentUserId));
        _pages.add(const SearchScreen());
        _pages.add(const ChatsScreen());
        _pages.add(const NotificationsScreen());
        _pages.add(const ProfileScreen());
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items:  <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: AppLocalizations.of(context)!.search,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: AppLocalizations.of(context)!.chat,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_activity),
            label: AppLocalizations.of(context)!.activity,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
