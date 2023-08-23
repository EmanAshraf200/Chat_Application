import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:scholar_chat/Screens/creategroupchatScreen.dart';
import 'package:scholar_chat/Screens/home_page.dart';
import 'package:scholar_chat/Screens/home_page_group.dart';

class User {
  final String firstName;
  final String secondName;
  final String imageUrl;
  final String email;
  bool isOnline;

  User({
    required this.firstName,
    required this.secondName,
    required this.imageUrl,
    required this.email,
    this.isOnline = false,
  });
}

class BottomNavScreen extends StatefulWidget {
  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? currentUserEmail;

  final List<Widget> _pages = [
    HomePage(),
    HomePageGroup(),
    CreateGroupChatScreen(),
  ];

  Timer? _offlineTimer;
  bool isOnline = false;
  bool otherUserIsOnline = false;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  void updateUserOnlineStatus(bool isOnline) {
    if (currentUserEmail == null) {
      return; // Return early if currentUserEmail is null
    }

    print('Updating user online status to: $isOnline');

    users.where('email', isEqualTo: currentUserEmail).get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final currentUserDoc = snapshot.docs.first;
        currentUserDoc.reference.update({'isOnline': isOnline});
      }
    });
  }

  // ... other methods ...
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (currentUserEmail == null) {
      return;
    }

    // Set user online status to true when the app is opened
    updateUserOnlineStatus(true);

    // Start listening to typing and presence
    startListeningToOtherUserOnlineStatus();

    // Start a timer to update user online status to false after 5 minutes of inactivity
    _startOfflineTimer();
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? presenceSubscription;

  void startListeningToOtherUserOnlineStatus() {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    String otherUserEmail = args['otherUserEmail'] ?? '';

    print('Start listening to online status for: $otherUserEmail');

    FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: otherUserEmail)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final isOnline = data?['isOnline'] ?? false;

        setState(() {
          otherUserIsOnline = isOnline;
        });
      } else {
        setState(() {
          otherUserIsOnline = false;
        });
      }
    });
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer(Duration(minutes: 5), () {
      updateUserOnlineStatus(false);
    });
  }

  void _resetOfflineTimer() {
    _offlineTimer?.cancel();
    _startOfflineTimer();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    fetchCurrentUserEmail();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      updateUserOnlineStatus(true);
      _resetOfflineTimer();
    } else if (state == AppLifecycleState.paused) {
      updateUserOnlineStatus(false);
    }
  }

  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _offlineTimer?.cancel();
    presenceSubscription?.cancel();

    updateUserOnlineStatus(false);

    super.dispose();
  }

  void fetchCurrentUserEmail() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        setState(() {
          currentUserEmail = user.email;
          updateUserOnlineStatus(true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Create Group Chat',
          ),
        ],
      ),
    );
  }
}
