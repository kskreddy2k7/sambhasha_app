import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<UserModel> _selectedUsers = [];
  bool _isLoading = false;

  void _toggleUser(UserModel user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name and select members")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final groupService = Provider.of<GroupService>(context, listen: false);

    try {
      await groupService.createGroup(
        name: _nameController.text.trim(),
        description: "",
        groupPic: "", // Default for now
        members: _selectedUsers.map((u) => u.uid).toList(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Group"),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text("Create", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Group Name",
                prefixIcon: const Icon(Icons.group_outlined),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Select Members", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              // For simplicity, we search all users here. 
              // In production, we might search contacts or recent chats.
              stream: db.searchUsers(""), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUsers.contains(user);
                    return ListTile(
                      onTap: () => _toggleUser(user),
                      leading: CircleAvatar(
                        backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                        child: user.profilePic.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user.name),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleUser(user),
                        activeColor: Colors.blueAccent,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
