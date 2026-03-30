import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sambhasha_app/models/story_model.dart';
import 'package:uuid/uuid.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  // Upload Story
  Future<void> uploadStory({
    required String name,
    required String profilePic,
    required String contentUrl,
    required StoryType type,
  }) async {
    String storyId = const Uuid().v4();
    StoryModel story = StoryModel(
      storyId: storyId,
      uid: currentUid,
      name: name,
      profilePic: profilePic,
      contentUrl: contentUrl,
      type: type,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('stories').doc(storyId).set(story.toMap());
  }

  // Get Active Stories (Posted in the last 24 hours)
  Stream<List<StoryModel>> getActiveStories() {
    DateTime twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
    
    return _firestore
        .collection('stories')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // View Story
  Future<void> viewStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).update({
      'viewers': FieldValue.arrayUnion([currentUid]),
    });
  }
}
