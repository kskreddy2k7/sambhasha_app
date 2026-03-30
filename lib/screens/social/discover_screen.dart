import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/screens/chat/chat_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.04),
              elevation: 0,
              title: const Text("Discover", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _query = val.trim()),
                      decoration: const InputDecoration(
                        hintText: "Search Sambhasha...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _query.isNotEmpty 
          ? _buildSearchResults() 
          : _buildDiscoveryFeed(),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<UserModel>>(
      stream: _db.searchUsers(_query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        if (users.isEmpty) return const Center(child: Text("No users found", style: TextStyle(color: Colors.grey)));
        
        return ListView.builder(
          padding: const EdgeInsets.only(top: 120),
          itemCount: users.length,
          itemBuilder: (context, index) => _UserListItem(user: users[index]),
        );
      },
    );
  }

  Widget _buildDiscoveryFeed() {
    return ListView(
      padding: const EdgeInsets.only(top: 120),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Suggested for You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<UserModel>>(
          future: _db.getSuggestedUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            final suggestions = snapshot.data!;
            if (suggestions.isEmpty) return const SizedBox();
            
            return SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                itemBuilder: (context, index) => _SuggestedUserCard(user: suggestions[index]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Recent Activity", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        // Add more social elements here later
      ],
    );
  }
}

class _UserListItem extends StatelessWidget {
  final UserModel user;
  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
        child: user.profilePic.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("@${user.phone.substring(user.phone.length - 4)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: StreamBuilder<bool>(
        stream: db.isFollowing(user.uid),
        builder: (context, snap) {
          final following = snap.data ?? false;
          return ElevatedButton(
            onPressed: () => following ? db.unfollowUser(user.uid) : db.followUser(user.uid),
            style: ElevatedButton.styleFrom(
              backgroundColor: following ? Colors.white.withOpacity(0.1) : Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 32),
            ),
            child: Text(following ? "Following" : "Follow", style: TextStyle(color: following ? Colors.white : Colors.white, fontSize: 12)),
          );
        },
      ),
    );
  }
}

class _SuggestedUserCard extends StatelessWidget {
  final UserModel user;
  const _SuggestedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
            child: user.profilePic.isEmpty ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(height: 8),
          Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          StreamBuilder<bool>(
            stream: db.isFollowing(user.uid),
            builder: (context, snap) {
              final following = snap.data ?? false;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => following ? db.unfollowUser(user.uid) : db.followUser(user.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: following ? Colors.white.withOpacity(0.08) : Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(following ? "Following" : "Follow", style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
