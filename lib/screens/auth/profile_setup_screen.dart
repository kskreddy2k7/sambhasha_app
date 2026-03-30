import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/providers/auth_provider.dart' as app_auth;
import 'package:sambhasha_app/screens/main_screen.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/widgets/loading_animation.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  String? _initialPhotoUrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? "";
      _initialPhotoUrl = user.photoURL;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  void _submit(app_auth.AuthProvider authProvider, DatabaseService db) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    authProvider.setLoading(true);

    try {
      String finalPhotoUrl = _initialPhotoUrl ?? "";
      
      // Upload new image if picked
      if (_imageBytes != null && _imageName != null) {
        finalPhotoUrl = await db.uploadImage(_imageBytes!, _imageName!);
      } else if (finalPhotoUrl.isEmpty) {
        // Fallback placeholder if no Google photo and no picked photo
        finalPhotoUrl = "https://ui-avatars.com/api/?name=${_nameController.text}&background=random";
      }

      await authProvider.saveUserDataToFirestore(
        name: _nameController.text.trim(),
        profilePic: finalPhotoUrl,
        onSuccess: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e")),
        );
      }
    } finally {
      authProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final db = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Color(0xFF0F172A)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Hero(
                        tag: 'logo',
                        child: Icon(Icons.forum_rounded, size: 80, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Setup Profile",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let others know who you are",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              backgroundImage: _imageBytes != null 
                                  ? MemoryImage(_imageBytes!) 
                                  : (_initialPhotoUrl != null ? NetworkImage(_initialPhotoUrl!) : null) as ImageProvider?,
                              child: (_imageBytes == null && _initialPhotoUrl == null)
                                  ? const Icon(Icons.person_outline, size: 60, color: Colors.blueAccent)
                                  : null,
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          hintStyle: const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.blueAccent),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : () => _submit(authProvider, db),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: Colors.blueAccent.withOpacity(0.4),
                          ),
                          child: authProvider.isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                "FINISH",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (authProvider.isLoading) const LoadingAnimation(),
        ],
      ),
    );
  }
}
