import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diy_guide.dart';
import '../models/saved_guide.dart';

class SavedGuideRepository {
  SavedGuideRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _savedGuides(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_guides');
  }

  Stream<Set<String>> watchSavedGuideIds(String userId) {
    return _savedGuides(userId).snapshots().map(
      (snapshot) => snapshot.docs.map((document) => document.id).toSet(),
    );
  }

  Stream<List<SavedGuide>> watchSavedGuides(String userId) {
    return _savedGuides(userId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(SavedGuide.fromFirestore).toList()
            ..sort((a, b) => a.title.compareTo(b.title)),
    );
  }

  Future<bool> isGuideSaved({
    required String userId,
    required String guideId,
  }) async {
    final document = await _savedGuides(userId).doc(guideId).get();
    return document.exists;
  }

  Future<void> saveGuide({required String userId, required DiyGuide guide}) {
    return _savedGuides(userId).doc(guide.id).set({
      'guide_id': guide.id,
      'title': guide.title,
      'image_url': guide.imageUrl,
      'difficulty_level': guide.difficultyLevel,
      'estimated_time': guide.estimatedTime,
      'saved_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unsaveGuide({required String userId, required String guideId}) {
    return _savedGuides(userId).doc(guideId).delete();
  }

  Future<void> toggleSavedGuide({
    required String userId,
    required DiyGuide guide,
  }) async {
    final isSaved = await isGuideSaved(userId: userId, guideId: guide.id);
    if (isSaved) {
      await unsaveGuide(userId: userId, guideId: guide.id);
      return;
    }
    await saveGuide(userId: userId, guide: guide);
  }
}
