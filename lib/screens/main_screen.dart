import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/call_model.dart';
import 'package:sambhasha_app/screens/call/incoming_call_screen.dart';
import 'package:sambhasha_app/screens/chat/recent_chats_screen.dart';
import 'package:sambhasha_app/screens/profile/profile_screen.dart';
import 'package:sambhasha_app/screens/search/search_screen.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/screens/social/discover_screen.dart';
import 'package:sambhasha_app/screens/ai/ai_assistant_screen.dart';


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
      const RecentChatsScreen(),
      const DiscoverScreen(),
      const AIAssistantScreen(),
      ProfileScreen(uid: uid),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: Colors.black,
          extendBody: true,
          body: Row(
            children: [
              if (isWide) _buildNavigationRail(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide ? null : _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelType: NavigationRailLabelType.none,
        selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        leading: const Column(
          children: [
            SizedBox(height: 20),
            Icon(Icons.forum_rounded, color: Colors.blueAccent, size: 32),
            SizedBox(height: 40),
          ],
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: Text('Chats'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: Text('Discover'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: Text('AI'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
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
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Discover',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_outlined),
                  activeIcon: Icon(Icons.auto_awesome),
                  label: 'AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
