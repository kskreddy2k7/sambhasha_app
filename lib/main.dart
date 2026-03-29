import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/screens/auth/login_screen.dart';
import 'package:sambhasha_app/screens/main_screen.dart';
import 'package:sambhasha_app/screens/splash/splash_screen.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/notification_service.dart';
import 'package:sambhasha_app/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<NotificationService>.value(value: notificationService),
        Provider<CallService>(
          create: (_) => CallService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const SambhashaApp(),
    ),
  );
}

class SambhashaApp extends StatelessWidget {
  const SambhashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sambhasha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1A1A1A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          final db = Provider.of<DatabaseService>(context, listen: false);
          db.setUserOnlineStatus(true);
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
