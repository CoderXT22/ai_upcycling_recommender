import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectSession {
  const ProjectSession({
    required this.id,
    required this.userId,
    required this.guideId,
    required this.guideTitle,
    this.guideImageUrl = '',
    this.beforeImageUrl = '',
    this.status = ProjectSessionStatuses.inProgress,
    this.startedAt,
    this.beforePhotoUploadedAt,
    this.completedAt,
    this.submissionId = '',
  });

  final String id;
  final String userId;
  final String guideId;
  final String guideTitle;
  final String guideImageUrl;
  final String beforeImageUrl;
  final String status;
  final DateTime? startedAt;
  final DateTime? beforePhotoUploadedAt;
  final DateTime? completedAt;
  final String submissionId;

  bool get hasBeforePhoto => beforeImageUrl.trim().isNotEmpty;

  String get statusLabel {
    return switch (status) {
      ProjectSessionStatuses.completedPrivate => 'Completed',
      ProjectSessionStatuses.waitingVerification => 'Waiting Verification',
      ProjectSessionStatuses.verified => 'Verified',
      ProjectSessionStatuses.published => 'Published',
      ProjectSessionStatuses.needMoreEvidence => 'Need More Evidence',
      _ => 'In Progress',
    };
  }

  String get startedAtText {
    final value = startedAt;
    if (value == null) return 'Started recently';
    return 'Started ${value.day}/${value.month}/${value.year}';
  }

  factory ProjectSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ProjectSession(
      id: document.id,
      userId: _stringValue(data['user_id']),
      guideId: _stringValue(data['guide_id']),
      guideTitle: _stringValue(data['guide_title']),
      guideImageUrl: _stringValue(data['guide_image_url']),
      beforeImageUrl: _stringValue(data['before_image_url']),
      status: _stringValue(
        data['status'],
        fallback: ProjectSessionStatuses.inProgress,
      ),
      startedAt: _dateTimeValue(data['started_at']),
      beforePhotoUploadedAt: _dateTimeValue(data['before_photo_uploaded_at']),
      completedAt: _dateTimeValue(data['completed_at']),
      submissionId: _stringValue(data['submission_id']),
    );
  }
}

class ProjectSessionStatuses {
  const ProjectSessionStatuses._();

  static const inProgress = 'in_progress';
  static const completedPrivate = 'completed_private';
  static const waitingVerification = 'waiting_verification';
  static const verified = 'verified';
  static const published = 'published';
  static const needMoreEvidence = 'need_more_evidence';

  static const values = [
    inProgress,
    completedPrivate,
    waitingVerification,
    verified,
    published,
    needMoreEvidence,
  ];
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
