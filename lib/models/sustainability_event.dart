import 'package:cloud_firestore/cloud_firestore.dart';

class SustainabilityEvent {
  const SustainabilityEvent({
    required this.id,
    required this.title,
    required this.organizer,
    required this.description,
    this.benefit = '',
    required this.date,
    this.startDate,
    this.rawEndDate,
    this.endDate = '',
    this.locationName = '',
    this.address = '',
    this.state = 'Selangor',
    this.requiredMaterials = const [],
    this.categoryTags = const [],
    this.materialKeywords = const [],
    required this.officialLink,
    this.imageUrl = '',
    required this.joinedCount,
    this.isActive = true,
    this.createdBy = '',
  });

  final String id;
  final String title;
  final String organizer;
  final String description;
  final String benefit;
  final String date;
  final DateTime? startDate;
  final DateTime? rawEndDate;
  final String endDate;
  final String locationName;
  final String address;
  final String state;
  final List<String> requiredMaterials;
  final List<String> categoryTags;
  final List<String> materialKeywords;
  final String officialLink;
  final String imageUrl;
  final int joinedCount;
  final bool isActive;
  final String createdBy;

  String get requiredMaterialsText {
    if (requiredMaterials.isEmpty) return 'Not specified';
    return requiredMaterials.join(', ');
  }

  String get displayLocation {
    if (locationName.isNotEmpty && address.isNotEmpty) {
      return '$locationName, $address';
    }
    if (locationName.isNotEmpty) return locationName;
    return address;
  }

  String get dateText {
    if (endDate.isEmpty || endDate == date) return date;
    return '$date - $endDate';
  }

  bool get isPast {
    final end = rawEndDate ?? startDate;
    if (end == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return endOnly.isBefore(todayOnly);
  }

  bool isOwnedBy(String userId) => createdBy == userId;

  factory SustainabilityEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return SustainabilityEvent(
      id: document.id,
      title: _stringValue(data['title']),
      organizer: _stringValue(data['organizer']),
      description: _stringValue(data['description']),
      benefit: _stringValue(data['benefit']),
      date: _dateValue(data['date']),
      startDate: _dateTimeValue(data['date']),
      rawEndDate: _dateTimeValue(data['end_date']),
      endDate: _dateValue(data['end_date']),
      locationName: _stringValue(data['location_name']),
      address: _stringValue(data['address']),
      state: _stringValue(data['state'], fallback: 'Selangor'),
      requiredMaterials: _stringList(data['required_materials']),
      categoryTags: _stringList(data['category_tags']),
      materialKeywords: _stringList(data['material_keywords']),
      officialLink: _stringValue(data['official_link']),
      imageUrl: _stringValue(data['image_url']),
      joinedCount: _intValue(data['joined_count']),
      isActive: data['is_active'] != false,
      createdBy: _stringValue(data['created_by']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String _dateValue(Object? value) {
  if (value is Timestamp) {
    final date = value.toDate();
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }
  return _stringValue(value);
}

DateTime? _dateTimeValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  return null;
}

String _monthName(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[month - 1];
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
