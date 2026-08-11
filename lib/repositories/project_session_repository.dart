import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diy_guide.dart';
import '../models/project_session.dart';

class ProjectSessionRepository {
  ProjectSessionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('project_sessions');

  Stream<List<ProjectSession>> watchUserSessions(String userId) {
    return _sessions.where('user_id', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final sessions = snapshot.docs
          .map(ProjectSession.fromFirestore)
          .toList();
      sessions.sort((a, b) {
        final aTime = a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return sessions;
    });
  }

  Stream<ProjectSession?> watchActiveGuideSession({
    required String userId,
    required String guideId,
  }) {
    return watchUserSessions(userId).map((sessions) {
      for (final session in sessions) {
        if (session.guideId == guideId &&
            session.status == ProjectSessionStatuses.inProgress) {
          return session;
        }
      }
      return null;
    });
  }

  Future<String> createSession({
    required String userId,
    required DiyGuide guide,
  }) async {
    final now = FieldValue.serverTimestamp();
    final document = await _sessions.add({
      'user_id': userId,
      'guide_id': guide.id,
      'guide_title': guide.title,
      'guide_image_url': guide.imageUrl,
      'before_image_url': '',
      'status': ProjectSessionStatuses.inProgress,
      'started_at': now,
      'updated_at': now,
      'submission_id': '',
    });
    return document.id;
  }

  Future<void> updateBeforePhoto({
    required String sessionId,
    required String beforeImageUrl,
  }) {
    return _sessions.doc(sessionId).update({
      'before_image_url': beforeImageUrl,
      'before_photo_uploaded_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCompletedPrivate(String sessionId) {
    return _sessions.doc(sessionId).update({
      'status': ProjectSessionStatuses.completedPrivate,
      'completed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markWaitingVerification({
    required String sessionId,
    required String submissionId,
    String? beforeImageUrl,
  }) {
    final data = <String, dynamic>{
      'status': ProjectSessionStatuses.waitingVerification,
      'completed_at': FieldValue.serverTimestamp(),
      'submission_id': submissionId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (beforeImageUrl != null && beforeImageUrl.trim().isNotEmpty) {
      data['before_image_url'] = beforeImageUrl.trim();
      data['before_photo_uploaded_at'] = FieldValue.serverTimestamp();
    }

    return _sessions.doc(sessionId).update(data);
  }

  Future<void> markReportGenerated({
    required String sessionId,
    required String submissionId,
    required String status,
    String? beforeImageUrl,
  }) {
    final data = <String, dynamic>{
      'status': status,
      'completed_at': FieldValue.serverTimestamp(),
      'submission_id': submissionId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (beforeImageUrl != null && beforeImageUrl.trim().isNotEmpty) {
      data['before_image_url'] = beforeImageUrl.trim();
      data['before_photo_uploaded_at'] = FieldValue.serverTimestamp();
    }

    return _sessions.doc(sessionId).update(data);
  }

  Future<void> markPublished(String sessionId) {
    return _sessions.doc(sessionId).update({
      'status': ProjectSessionStatuses.published,
      'published_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
