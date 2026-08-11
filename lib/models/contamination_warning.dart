import 'package:cloud_firestore/cloud_firestore.dart';

class ContaminationWarning {
  const ContaminationWarning({
    required this.id,
    required this.title,
    required this.warning,
    this.severity = 'medium',
    this.categoryTags = const [],
    this.materialTags = const [],
    this.objectTags = const [],
    this.isActive = true,
  });

  final String id;
  final String title;
  final String warning;
  final String severity;
  final List<String> categoryTags;
  final List<String> materialTags;
  final List<String> objectTags;
  final bool isActive;

  factory ContaminationWarning.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return ContaminationWarning(
      id: document.id,
      title: _stringValue(data['title']),
      warning: _stringValue(data['warning']),
      severity: _stringValue(data['severity'], fallback: 'medium'),
      categoryTags: _stringList(data['category_tags']),
      materialTags: _stringList(data['material_tags']),
      objectTags: _stringList(data['object_tags']),
      isActive: data['is_active'] != false,
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) return value.whereType<String>().toList();
  return const [];
}
