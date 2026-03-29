import 'dart:io';
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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(DatabaseService db) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() => _isSaving = true);
      try {
        String url = await db.uploadImage(File(pickedFile.path));
        await db.updateProfile(photoURL: url);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile(DatabaseService db) async {
    setState(() => _isSaving = true);
    try {
      await db.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);
    final bool isMe = auth.currentUser?.uid == widget.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.logout(),
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: db.getUserData(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          if (!_isEditing) {
            _usernameController.text = user.username;
            _bioController.text = user.bio ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                      child: user.photoURL == null
                          ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                    if (isMe)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: _isSaving ? null : () => _pickAndUploadImage(db),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isEditing) ...[
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveProfile(db),
                        child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(user.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text(user.bio?.isEmpty ?? true ? 'No bio' : user.bio!, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  if (isMe)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _isEditing = true),
                        child: const Text('Edit Profile'),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
