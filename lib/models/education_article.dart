import 'package:cloud_firestore/cloud_firestore.dart';

class EducationArticle {
  const EducationArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.content = '',
    required this.category,
    this.tags = const [],
    this.readTime = '',
    this.imageUrl = '',
    this.sourceTitle = '',
    this.sourceUrl = '',
    this.sourceType = '',
    this.isActive = true,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String category;
  final List<String> tags;
  final String readTime;
  final String imageUrl;
  final String sourceTitle;
  final String sourceUrl;
  final String sourceType;
  final bool isActive;

  factory EducationArticle.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return EducationArticle(
      id: document.id,
      title: _stringValue(data['title']),
      summary: _stringValue(data['summary']),
      content: _stringValue(data['content']),
      category: _stringValue(data['category']),
      tags: _stringList(data['tags']),
      readTime: _stringValue(data['read_time']),
      imageUrl: _stringValue(data['image_url']),
      sourceTitle: _stringValue(data['source_title']),
      sourceUrl: _stringValue(data['source_url']),
      sourceType: _stringValue(data['source_type']),
      isActive: data['is_active'] != false,
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList();
  }
  return const [];
}
