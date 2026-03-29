import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  late DatabaseService _db;
  late bool _isMe;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
    _isMe = FirebaseAuth.instance.currentUser!.uid == widget.uid;
  }

  Future<void> _updateProfile(UserModel user) async {
    final updatedUser = UserModel(
      uid: user.uid,
      name: _nameController.text,
      email: user.email,
      bio: _bioController.text,
      profilePhoto: user.profilePhoto,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      pushToken: user.pushToken,
    );
    await _db.updateUserData(updatedUser);
    setState(() => _isEditing = false);
  }

  Future<void> _pickImage(UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String url = await _db.uploadMedia(File(pickedFile.path), 'profile_photos');
      final updatedUser = UserModel(
        uid: user.uid,
        name: user.name,
        email: user.email,
        bio: user.bio,
        profilePhoto: url,
        isOnline: user.isOnline,
        lastSeen: user.lastSeen,
        pushToken: user.pushToken,
      );
      await _db.updateUserData(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isMe)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Provider.of<AuthService>(context, listen: false).logout(),
            ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: _db.getUserData(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;
          if (!_isEditing) {
            _nameController.text = user.name;
            _bioController.text = user.bio ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isMe ? () => _pickImage(user) : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundImage: user.profilePhoto != null
                            ? NetworkImage(user.profilePhoto!)
                            : null,
                        child: user.profilePhoto == null
                            ? const Icon(Icons.person, size: 64)
                            : null,
                      ),
                      if (_isMe)
                        const Positioned(
                          bottom: 0,
                          right: 4,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.edit, size: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _isEditing
                    ? TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: 'Name'),
                      )
                    : Text(
                        user.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                const SizedBox(height: 8),
                Text(user.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                _isEditing
                    ? TextField(
                        controller: _bioController,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: 'Bio'),
                      )
                    : Text(
                        user.bio ?? 'No bio available',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                const SizedBox(height: 32),
                if (_isMe)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isEditing) {
                          _updateProfile(user);
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditing ? Colors.green : Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
