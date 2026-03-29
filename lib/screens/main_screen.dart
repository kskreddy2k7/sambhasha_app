import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/screens/call/incoming_call_screen.dart';
import 'package:sambhasha_app/screens/home/home_screen.dart';
import 'package:sambhasha_app/screens/profile/profile_screen.dart';
import 'package:sambhasha_app/screens/search/search_screen.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/database_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Track the callId currently shown to avoid duplicate navigation.
  String? _activeIncomingCallId;
  StreamSubscription<CallModel?>? _callSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
    _listenForIncomingCalls();
  }

  void _setOnline(bool isOnline) {
    Provider.of<DatabaseService>(context, listen: false)
        .setUserOnlineStatus(isOnline);
  }

  void _listenForIncomingCalls() {
    final callService = Provider.of<CallService>(context, listen: false);
    _callSub = callService.listenForIncomingCalls().listen((call) {
      if (call == null || call.callId == _activeIncomingCallId || !mounted) {
        return;
      }
      _activeIncomingCallId = call.callId;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            call: call,
            onCallEnded: () => _activeIncomingCallId = null,
          ),
        ),
      ).then((_) => _activeIncomingCallId = null);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setOnline(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      ProfileScreen(uid: uid),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search, size: 28),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
