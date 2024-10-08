import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? profilePictureUrl;
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

      await _getUserProfilePicture();

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

  Future<void> _getUserProfilePicture() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userDoc.exists) {
      setState(() {
        profilePictureUrl = userDoc.data()?['profile_picture'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _pages[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor:
              Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          backgroundColor:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ),
        child: NavigationBar(
          onDestinationSelected: _onItemTapped,
          selectedIndex: _currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_filled),
              label: AppLocalizations.of(context)!.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search),
              label: AppLocalizations.of(context)!.search,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat),
              label: AppLocalizations.of(context)!.chat,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications),
              label: AppLocalizations.of(context)!.activity,
            ),
            NavigationDestination(
              icon: profilePictureUrl != null
                  ? CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(profilePictureUrl!),
                      radius: 12,
                    )
                  : const Icon(Icons.person),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
    );
  }
}
