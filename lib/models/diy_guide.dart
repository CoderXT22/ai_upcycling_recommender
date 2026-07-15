import 'package:cloud_firestore/cloud_firestore.dart';

class DiyGuide {
  const DiyGuide({
    required this.id,
    required this.title,
    required this.description,
    this.objectTags = const [],
    required this.materialTags,
    this.categoryTags = const [],
    required this.materialsNeeded,
    required this.steps,
    required this.difficultyLevel,
    required this.estimatedTime,
    required this.savedCount,
    this.imageUrl = '',
    this.videoUrl = '',
    this.videoType = '',
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final List<String> objectTags;
  final List<String> materialTags;
  final List<String> categoryTags;
  final List<String> materialsNeeded;
  final List<String> steps;
  final String difficultyLevel;
  final String estimatedTime;
  final int savedCount;
  final String imageUrl;
  final String videoUrl;
  final String videoType;
  final bool isActive;

  bool get hasVideo => videoUrl.trim().isNotEmpty;

  factory DiyGuide.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return DiyGuide(
      id: document.id,
      title: _stringValue(data['title']),
      description: _stringValue(data['description']),
      objectTags: _stringList(data['object_tags']),
      materialTags: _stringList(data['material_tags']),
      categoryTags: _stringList(data['category_tags']),
      materialsNeeded: _stringList(data['materials_needed']),
      steps: _stringList(data['steps']),
      difficultyLevel: _stringValue(data['difficulty_level'], fallback: 'easy'),
      estimatedTime: _stringValue(data['estimated_time']),
      imageUrl: _stringValue(data['image_url']),
      videoUrl: _stringValue(data['video_url']),
      videoType: _stringValue(data['video_type']),
      savedCount: _intValue(data['saved_count']),
      isActive: data['is_active'] != false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'object_tags': objectTags,
      'material_tags': materialTags,
      'category_tags': categoryTags,
      'materials_needed': materialsNeeded,
      'steps': steps,
      'difficulty_level': difficultyLevel,
      'estimated_time': estimatedTime,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'video_type': videoType,
      'saved_count': savedCount,
      'is_active': isActive,
    };
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList();
  }
  return const [];
}
