import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/story_model.dart';
import 'package:sambhasha_app/services/story_service.dart';
import 'package:sambhasha_app/widgets/skeleton_loading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sambhasha_app/providers/auth_provider.dart' as app_auth;
import 'package:sambhasha_app/services/database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sambhasha_app/screens/story/story_viewer_screen.dart';

class StoryBar extends StatefulWidget {
  const StoryBar({super.key});

  @override
  State<StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<StoryBar> {
  bool _isUploading = false;

  void _pickAndUploadStory(BuildContext context) async {
    final picker = ImagePicker();
    final userProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final databaseService = DatabaseService();
    final storyService = Provider.of<StoryService>(context, listen: false);

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final imageUrl = await databaseService.uploadImage(bytes, pickedFile.name);

      await storyService.uploadStory(
        name: userProvider.userModel?.name ?? 'User',
        profilePic: userProvider.userModel?.profilePic ?? '',
        contentUrl: imageUrl,
        type: StoryType.image,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Story uploaded successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading story: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context, listen: false);
    final userProvider = Provider.of<app_auth.AuthProvider>(context);

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<List<StoryModel>>(
        stream: storyService.getActiveStories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonLoader(height: 80, width: double.infinity);
          }

          final stories = snapshot.data ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // "Your Story" item
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _pickAndUploadStory(context),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[900],
                              backgroundImage: userProvider.userModel?.profilePic != null && userProvider.userModel!.profilePic.isNotEmpty
                                  ? CachedNetworkImageProvider(userProvider.userModel!.profilePic)
                                  : null,
                              child: userProvider.userModel?.profilePic == null || userProvider.userModel!.profilePic.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white24, size: 30)
                                  : null,
                            ),
                            if (_isUploading)
                              const Positioned.fill(
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Your Story",
                          style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final story = stories[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(stories: stories, initialIndex: index - 1),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.orange, Colors.red],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black,
                          backgroundImage: story.profilePic.isNotEmpty 
                              ? CachedNetworkImageProvider(story.profilePic) 
                              : null,
                          child: story.profilePic.isEmpty 
                              ? Text(story.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story.name.split(' ')[0],
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
