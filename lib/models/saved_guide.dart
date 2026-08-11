import 'package:cloud_firestore/cloud_firestore.dart';

class SavedGuide {
  const SavedGuide({
    required this.guideId,
    required this.title,
    this.imageUrl = '',
    this.difficultyLevel = '',
    this.estimatedTime = '',
  });

  final String guideId;
  final String title;
  final String imageUrl;
  final String difficultyLevel;
  final String estimatedTime;

  factory SavedGuide.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return SavedGuide(
      guideId: _stringValue(data['guide_id'], fallback: document.id),
      title: _stringValue(data['title'], fallback: 'Saved DIY Guide'),
      imageUrl: _stringValue(data['image_url']),
      difficultyLevel: _stringValue(data['difficulty_level']),
      estimatedTime: _stringValue(data['estimated_time']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}
