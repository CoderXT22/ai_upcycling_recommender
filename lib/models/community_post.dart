import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.caption,
    this.imageUrl = '',
    this.colorLabel = 'DIY project',
    this.likeCount = 0,
    this.commentCount = 0,
    this.visibility = 'public',
    this.createdAtText = 'Just now',
  });

  final String id;
  final String userId;
  final String authorName;
  final String caption;
  final String imageUrl;
  final String colorLabel;
  final int likeCount;
  final int commentCount;
  final String visibility;
  final String createdAtText;

  String get timeAgo => createdAtText;

  factory CommunityPost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return CommunityPost(
      id: document.id,
      userId: _stringValue(data['user_id']),
      authorName: _stringValue(data['author_name'], fallback: 'EcoLoop User'),
      caption: _stringValue(data['caption']),
      imageUrl: _stringValue(data['image_url']),
      colorLabel: _stringValue(data['color_label'], fallback: 'DIY project'),
      likeCount: _intValue(data['like_count']),
      commentCount: _intValue(data['comment_count']),
      visibility: _stringValue(data['visibility'], fallback: 'public'),
      createdAtText: _timestampText(data['created_at']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
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
