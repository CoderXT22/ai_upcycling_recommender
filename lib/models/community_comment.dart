import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.text,
    this.createdAtText = 'Just now',
  });

  final String id;
  final String userId;
  final String authorName;
  final String text;
  final String createdAtText;

  factory CommunityComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return CommunityComment(
      id: document.id,
      userId: _stringValue(data['user_id']),
      authorName: _stringValue(data['author_name'], fallback: 'EcoLoop User'),
      text: _stringValue(data['text']),
      createdAtText: _timestampText(data['created_at']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

String _timestampText(Object? value) {
  if (value is! Timestamp) return 'Just now';

  final createdAt = value.toDate();
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}
