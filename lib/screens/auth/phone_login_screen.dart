import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/providers/auth_provider.dart';
import 'package:sambhasha_app/screens/auth/profile_setup_screen.dart';
import 'package:sambhasha_app/widgets/loading_animation.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  bool _codeSent = false;

  void _sendOTP() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    // Ensure phone starts with +
    if (!phone.startsWith('+')) {
       if (!context.mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Include country code (e.g., +1)"))
       );
       return;
    }

    auth.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (id) => setState(() {
        _verificationId = id;
        _codeSent = true;
      }),
      onError: (err) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
        );
      },
    );
  }

  void _verifyOTP() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.signInWithPhone(_verificationId, _otpController.text.trim());

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      if (mounted) {
        // Successful login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
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
                const Icon(Icons.phone_android_rounded, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 24),
                Text(
                  _codeSent ? "Verify OTP" : "Phone Login",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _codeSent 
                    ? "Enter the 6-digit code sent to ${_phoneController.text}"
                    : "Enter your phone number to continue",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                if (!_codeSent) ...[
                  // PHONE INPUT
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "+1 123 456 7890",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Send Code", style: TextStyle(fontSize: 18)),
                  ),
                ] else ...[
                  // OTP PIN ENTRY
                  Pinput(
                    length: 6,
                    controller: _otpController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: Colors.blueAccent),
                      ),
                    ),
                    onCompleted: (pin) => _verifyOTP(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Verify & Login", style: TextStyle(fontSize: 18)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _codeSent = false),
                    child: const Text("Change Number", style: TextStyle(color: Colors.grey)),
                  ),
                ],

                const SizedBox(height: 32),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white60),
                ),
              ],
            ),
          ),
          if (auth.isLoading) const LoadingAnimation(),
        ],
      ),
    );
  }
}

