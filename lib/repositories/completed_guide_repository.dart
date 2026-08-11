import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diy_guide.dart';
import '../models/project_session.dart';

class CompletedGuideRepository {
  CompletedGuideRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _completedGuides(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('completed_guides');
  }

  Stream<bool> watchIsCompleted({
    required String userId,
    required String guideId,
  }) {
    return _completedGuides(
      userId,
    ).doc(guideId).snapshots().map((snapshot) => snapshot.exists);
  }

  Future<void> markCompleted({
    required String userId,
    required DiyGuide guide,
  }) {
    return _completedGuides(userId).doc(guide.id).set({
      'guide_id': guide.id,
      'title': guide.title,
      'completed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markCompletedFromSession({
    required String userId,
    required ProjectSession session,
  }) {
    return _completedGuides(userId).doc(session.guideId).set({
      'guide_id': session.guideId,
      'title': session.guideTitle,
      'completed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unmarkCompleted({
    required String userId,
    required String guideId,
  }) {
    return _completedGuides(userId).doc(guideId).delete();
  }
}
