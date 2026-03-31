import 'package:flutter/material.dart';
import 'package:sambhasha_app/models/group_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/services/group_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupDetailsScreen extends StatelessWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  void _promoteToAdmin(BuildContext context, String uid) async {
    await GroupService().promoteToAdmin(group.groupId, uid);
    if (context.mounted) Navigator.pop(context);
  }

  void _removeFromGroup(BuildContext context, String uid) async {
    await GroupService().removeMember(group.groupId, uid);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final isAdmin = group.admins.contains(db.currentUid);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Group Info"),
      ),
      body: ListView(
        children: [
          // HEADER
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: group.groupPic.isNotEmpty ? CachedNetworkImageProvider(group.groupPic) : null,
              child: group.groupPic.isEmpty ? const Icon(Icons.group, size: 60) : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              group.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "${group.members.length} members",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),

          // MEMBERS SECTION
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "MEMBERS",
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.members.length,
            itemBuilder: (context, index) {
              final memberUid = group.members[index];
              return StreamBuilder<UserModel?>(
                stream: db.getUserData(memberUid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final user = snapshot.data!;
                  final isMemberAdmin = group.admins.contains(user.uid);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.profilePic.isNotEmpty ? CachedNetworkImageProvider(user.profilePic) : null,
                      child: user.profilePic.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(user.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(user.isOnline ? "Online" : "Offline", style: TextStyle(color: user.isOnline ? Colors.greenAccent : Colors.grey, fontSize: 12)),
                    trailing: isMemberAdmin 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("ADMIN", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      : null,
                    onLongPress: (isAdmin && user.uid != db.currentUid) ? () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1E293B),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMemberAdmin)
                                ListTile(
                                  leading: const Icon(Icons.security, color: Colors.blueAccent),
                                  title: const Text("Make Group Admin", style: TextStyle(color: Colors.white)),
                                  onTap: () => _promoteToAdmin(context, user.uid),
                                ),
                              ListTile(
                                leading: const Icon(Icons.person_remove, color: Colors.redAccent),
                                title: const Text("Remove from Group", style: TextStyle(color: Colors.redAccent)),
                                onTap: () => _removeFromGroup(context, user.uid),
                              ),
                            ],
                          ),
                        ),
                      );
                    } : null,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

