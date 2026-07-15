import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclingCentre {
  const RecyclingCentre({
    required this.id,
    required this.name,
    this.centreType = 'recycling',
    required this.address,
    this.state = 'Selangor',
    this.area = '',
    this.latitude,
    this.longitude,
    this.acceptedCategories = const [],
    required this.acceptedMaterials,
    required this.operatingHours,
    this.contactInfo = '',
    this.officialLink = '',
    this.distance = '',
    required this.status,
    this.lastVerifiedAt = '',
    required this.lastUpdated,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String centreType;
  final String address;
  final String state;
  final String area;
  final double? latitude;
  final double? longitude;
  final List<String> acceptedCategories;
  final List<String> acceptedMaterials;
  final String operatingHours;
  final String contactInfo;
  final String officialLink;
  final String distance;
  final String status;
  final String lastVerifiedAt;
  final String lastUpdated;
  final bool isActive;

  factory RecyclingCentre.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return RecyclingCentre(
      id: document.id,
      name: _stringValue(data['name']),
      centreType: _stringValue(data['centre_type'], fallback: 'recycling'),
      address: _stringValue(data['address']),
      state: _stringValue(data['state'], fallback: 'Selangor'),
      area: _stringValue(data['area']),
      latitude: _doubleValue(data['latitude']),
      longitude: _doubleValue(data['longitude']),
      acceptedCategories: _stringList(data['accepted_categories']),
      acceptedMaterials: _stringList(data['accepted_materials']),
      operatingHours: _stringValue(data['operating_hours']),
      contactInfo: _stringValue(data['contact_info']),
      officialLink: _stringValue(data['official_link']),
      status: _stringValue(data['status'], fallback: 'unknown'),
      lastVerifiedAt: _dateValue(data['last_verified_at']),
      lastUpdated: _dateValue(data['updated_at']),
      isActive: data['is_active'] != false,
    );
  }

  bool acceptsCategory(String category) {
    if (category == 'all') return true;
    final normalized = category.toLowerCase();
    return acceptedCategories
        .map((value) => value.toLowerCase())
        .contains(normalized);
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

double? _doubleValue(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return null;
}

String _dateValue(Object? value) {
  if (value is Timestamp) {
    final date = value.toDate();
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }
  return _stringValue(value);
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

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList();
  }
  return const [];
}
