import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/services/local_auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final lockService = LocalAuthService();
    final enabled = await lockService.isLockEnabled();
    if (mounted) setState(() => _isAppLockEnabled = enabled);
  }

  void _saveProfile(DatabaseService db) async {
    setState(() => _isSaving = true);
    await db.updateProfile(name: _nameController.text.trim());
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
    }
  }

  void _pickAndUploadImage(DatabaseService db) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isSaving = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final url = await db.uploadImage(bytes, pickedFile.name);
      await db.updateProfile(profilePic: url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUid = auth.currentUser?.uid;
    final bool isMe = currentUid == widget.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isMe ? 'My Profile' : 'Profile'),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => auth.logout(),
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: db.getUserData(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;
          if (!_isEditing) _nameController.text = user.name;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileAvatar(user, isMe, db),
                const SizedBox(height: 24),
                _buildSocialStats(db, widget.uid),
                const SizedBox(height: 32),
                if (_isEditing) _buildEditForm(db) else _buildProfileInfo(user, isMe, db),
                if (isMe) _buildSettingsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel user, bool isMe, DatabaseService db) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent.withValues(alpha: 0.5)]),
          ),
          child: CircleAvatar(
            radius: 70,
            backgroundColor: Colors.black,
            backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
            child: user.profilePic.isEmpty ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40)) : null,
          ),
        ),
        if (isMe)
          Positioned(bottom: 5, right: 5, child: _buildCameraButton(db)),
      ],
    );
  }

  Widget _buildCameraButton(DatabaseService db) {
    return CircleAvatar(
      backgroundColor: Colors.blueAccent,
      radius: 20,
      child: IconButton(
        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
        onPressed: _isSaving ? null : () => _pickAndUploadImage(db),
      ),
    );
  }

  Widget _buildSocialStats(DatabaseService db, String uid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("Followers", db.getFollowersCount(uid)),
        _buildStatItem("Following", db.getFollowingCount(uid)),
      ],
    );
  }

  Widget _buildStatItem(String label, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        return Column(
          children: [
            Text("${snap.data ?? 0}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        );
      },
    );
  }

  Widget _buildProfileInfo(UserModel user, bool isMe, DatabaseService db) {
    return Column(
      children: [
        Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(user.phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 24),
        if (!isMe)
          StreamBuilder<bool>(
            stream: db.isFollowing(user.uid),
            builder: (context, snap) {
              final following = snap.data ?? false;
              return SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => following ? db.unfollowUser(user.uid) : db.followUser(user.uid),
                  style: ElevatedButton.styleFrom(backgroundColor: following ? Colors.white10 : Colors.blueAccent),
                  child: Text(following ? "Following" : "Follow"),
                ),
              );
            },
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
               onPressed: () => setState(() => _isEditing = true),
               child: const Text("Edit Profile"),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Divider(color: Colors.white12),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text("Privacy & Security", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
        SwitchListTile(
          title: const Text("App Lock (Biometric)"),
          subtitle: const Text("Require fingerprint/PIN to open Sambhasha"),
          value: _isAppLockEnabled,
          activeColor: Colors.blueAccent,
          onChanged: (val) async {
            final lockService = LocalAuthService();
            await lockService.setLockEnabled(val);
            setState(() => _isAppLockEnabled = val);
          },
        ),
      ],
    );
  }

  Widget _buildEditForm(DatabaseService db) {
    return Column(
      children: [
        TextField(
          controller: _nameController, 
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel')),
            ElevatedButton(onPressed: _isSaving ? null : () => _saveProfile(db), child: const Text('Save')),
          ],
        ),
      ],
    );
  }
}

