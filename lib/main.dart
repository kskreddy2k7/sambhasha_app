import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/firebase_options.dart';
import 'package:sambhasha_app/providers/auth_provider.dart';
import 'package:sambhasha_app/providers/chat_provider.dart';
import 'package:sambhasha_app/providers/navigation_provider.dart';
import 'package:sambhasha_app/screens/auth/login_screen.dart';
import 'package:sambhasha_app/screens/main_screen.dart';
import 'package:sambhasha_app/screens/splash/splash_screen.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/notification_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/screens/auth/config_error_screen.dart';
import 'package:sambhasha_app/services/ai_service.dart';
import 'package:sambhasha_app/services/story_service.dart';
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
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AIService>(create: (_) => AIService()),
        Provider<StoryService>(create: (_) => StoryService()),
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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2E6FF2),
        scaffoldBackgroundColor: const Color(0xFF050505),
        fontFamily: 'Inter', // Assuming standard fallback
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2E6FF2),
          secondary: Color(0xFF2E6FF2),
          surface: Color(0xFF121212),
          error: Color(0xFFFF4B4B),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E6FF2),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF222222),
          thickness: 1,
          space: 1,
        ),
      ),
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
              
              if (mounted) {
                final db = Provider.of<DatabaseService>(context, listen: false);
                db.setUserOnlineStatus(true);

                final ns = Provider.of<NotificationService>(context, listen: false);
                ns.updateToken(authService.currentUser!.uid);
              }

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

