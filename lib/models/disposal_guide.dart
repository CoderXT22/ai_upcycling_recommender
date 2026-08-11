import 'package:cloud_firestore/cloud_firestore.dart';

class DisposalGuide {
  const DisposalGuide({
    required this.id,
    required this.title,
    required this.instruction,
    this.categoryTags = const [],
    this.materialTags = const [],
    this.objectTags = const [],
    this.isActive = true,
  });

  final String id;
  final String title;
  final String instruction;
  final List<String> categoryTags;
  final List<String> materialTags;
  final List<String> objectTags;
  final bool isActive;

  factory DisposalGuide.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return DisposalGuide(
      id: document.id,
      title: _stringValue(data['title']),
      instruction: _stringValue(data['instruction']),
      categoryTags: _stringList(data['category_tags']),
      materialTags: _stringList(data['material_tags']),
      objectTags: _stringList(data['object_tags']),
      isActive: data['is_active'] != false,
    );
  }
}

String _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return '';
}

List<String> _stringList(Object? value) {
  if (value is Iterable) return value.whereType<String>().toList();
  return const [];
}
