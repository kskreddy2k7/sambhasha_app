import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/firebase_options.dart';
import 'package:sambhasha_app/providers/auth_provider.dart';
import 'package:sambhasha_app/providers/chat_provider.dart';
import 'package:sambhasha_app/screens/auth/login_screen.dart';
import 'package:sambhasha_app/screens/main_screen.dart';
import 'package:sambhasha_app/screens/splash/splash_screen.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/notification_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/screens/auth/config_error_screen.dart';
import 'package:sambhasha_app/services/ai_service.dart';
import 'package:sambhasha_app/services/local_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");


  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    isFirebaseInitialized = false;
  }

  final notificationService = NotificationService();
  if (isFirebaseInitialized) {
    await notificationService.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AIService>(create: (_) => AIService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<NotificationService>.value(value: notificationService),
        Provider<CallService>(
          create: (_) => CallService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: SambhashaApp(isFirebaseInitialized: isFirebaseInitialized),
    ),
  );
}

class SambhashaApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  const SambhashaApp({super.key, required this.isFirebaseInitialized});

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
      // If Firebase failed, show the error screen. Otherwise, proceed to AuthWrapper.
      home: isFirebaseInitialized ? const AuthWrapper() : const ConfigErrorScreen(),
    );
  }
}


class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLocked = true;
  bool _isLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  void _checkLockStatus() async {
    final lockService = LocalAuthService();
    final enabled = await lockService.isLockEnabled();
    setState(() => _isLockEnabled = enabled);
    if (enabled) {
      _authenticate();
    } else {
      setState(() => _isLocked = false);
    }
  }

  void _authenticate() async {
    final lockService = LocalAuthService();
    final success = await lockService.authenticate();
    if (success) {
      setState(() => _isLocked = false);
    } else {
      // Stay locked
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData) {
          // If App Lock is on and we haven't authenticated yet, show Lock Screen
          if (_isLockEnabled && _isLocked) {
            return _buildLockScreen();
          }

          return FutureBuilder(
            future: Provider.of<AuthProvider>(context, listen: false).fetchUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              
              final db = Provider.of<DatabaseService>(context, listen: false);
              db.setUserOnlineStatus(true);

              final ns = Provider.of<NotificationService>(context, listen: false);
              ns.updateToken(authService.currentUser!.uid);

              return const MainScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text("Sambhasha is Locked", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text("Unlock with Biometrics"),
            ),
          ],
        ),
      ),
    );
  }
}
