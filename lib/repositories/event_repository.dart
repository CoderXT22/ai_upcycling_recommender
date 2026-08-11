import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sustainability_event.dart';

class EventRepository {
  EventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SustainabilityEvent>> watchActiveEvents() {
    return _firestore
        .collection('events')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                .map(SustainabilityEvent.fromFirestore)
                .where((event) => event.isActive)
                .toList()
                ..sort(_sortByDateThenTitle),
        );
  }

  Future<List<SustainabilityEvent>> fetchActiveEvents() async {
    final snapshot = await _firestore.collection('events').get();
    return snapshot.docs
        .map(SustainabilityEvent.fromFirestore)
        .where((event) => event.isActive)
        .toList()
      ..sort(_sortByDateThenTitle);
  }

  Future<void> createOrganisationEvent({
    required String organisationUserId,
    required String organiser,
    required String title,
    required String description,
    required String benefit,
    required DateTime startDate,
    required DateTime endDate,
    required String locationName,
    required String address,
    required List<String> requiredMaterials,
    required String officialLink,
    required String imageUrl,
  }) {
    final materialKeywords = requiredMaterials
        .map((material) => material.trim().toLowerCase())
        .where((material) => material.isNotEmpty)
        .toSet()
        .toList();
    return _firestore.collection('events').add({
      'created_by': organisationUserId,
      'created_by_role': 'organisation_user',
      'title': title.trim(),
      'organizer': organiser.trim(),
      'description': description.trim(),
      'benefit': benefit.trim(),
      'date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'location_name': locationName.trim(),
      'address': address.trim(),
      'state': 'Selangor',
      'required_materials': requiredMaterials,
      'material_keywords': materialKeywords,
      'category_tags': materialKeywords,
      'official_link': officialLink.trim(),
      'image_url': imageUrl.trim(),
      'joined_count': 0,
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrganisationEvent({
    required String eventId,
    required String organisationUserId,
    required String organiser,
    required String title,
    required String description,
    required String benefit,
    required DateTime startDate,
    required DateTime endDate,
    required String locationName,
    required String address,
    required List<String> requiredMaterials,
    required String officialLink,
    required String imageUrl,
  }) {
    final materialKeywords = _materialKeywords(requiredMaterials);
    return _firestore.collection('events').doc(eventId).update({
      'created_by': organisationUserId,
      'created_by_role': 'organisation_user',
      'title': title.trim(),
      'organizer': organiser.trim(),
      'description': description.trim(),
      'benefit': benefit.trim(),
      'date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'location_name': locationName.trim(),
      'address': address.trim(),
      'state': 'Selangor',
      'required_materials': requiredMaterials,
      'material_keywords': materialKeywords,
      'category_tags': materialKeywords,
      'official_link': officialLink.trim(),
      'image_url': imageUrl.trim(),
      'is_active': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOrganisationEvent(String eventId) {
    return _firestore.collection('events').doc(eventId).delete();
  }

  List<String> _materialKeywords(List<String> requiredMaterials) {
    return requiredMaterials
        .map((material) => material.trim().toLowerCase())
        .where((material) => material.isNotEmpty)
        .toSet()
        .toList();
  }

  int _sortByDateThenTitle(SustainabilityEvent a, SustainabilityEvent b) {
    final aDate = a.startDate ?? DateTime(9999);
    final bDate = b.startDate ?? DateTime(9999);
    final dateComparison = aDate.compareTo(bDate);
    if (dateComparison != 0) return dateComparison;
    return a.title.compareTo(b.title);
  }
}
