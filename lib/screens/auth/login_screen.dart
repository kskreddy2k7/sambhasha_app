import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/providers/auth_provider.dart';
import 'package:sambhasha_app/screens/auth/phone_login_screen.dart';
import 'package:sambhasha_app/screens/auth/profile_setup_screen.dart';
import 'package:sambhasha_app/widgets/loading_animation.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleGoogleSignIn(BuildContext context, AuthProvider authProvider) async {
    final error = await authProvider.signInWithGoogle();
    
    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      if (context.mounted) {
        if (authProvider.userModel == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
            (route) => false,
          );
        } else {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Color(0xFF0F172A)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                const Hero(
                  tag: 'logo',
                  child: Icon(Icons.forum_rounded, size: 100, color: Colors.blueAccent),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Sambhasha",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Real-time Secure Messaging Experience",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 0.8),
                ),
                const Spacer(flex: 2),
                
                // AUTH OPTIONS
                ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : () => _handleGoogleSignIn(context, authProvider),
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 22,
                    width: 22,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                  ),
                  label: const Text("Continue with Google", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: authProvider.isLoading ? null : () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
                  },
                  icon: const Icon(Icons.phone_android_rounded, color: Colors.blueAccent),
                  label: const Text("Continue with Phone", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
                
                const Spacer(flex: 2),
                const Text(
                  "High-Fidelity Security • Production-Ready Engine",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (authProvider.isLoading) const LoadingAnimation(),
        ],
      ),
    );
  }
}

