import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/organisation_profile.dart';

class OrganisationRepository {
  OrganisationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _organisations =>
      _firestore.collection('organisations');

  Stream<OrganisationProfile?> watchOrganisationForUser(String userId) {
    return _organisations.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return OrganisationProfile.fromFirestore(snapshot);
    });
  }

  Future<OrganisationProfile?> fetchOrganisationForUser(String userId) async {
    final snapshot = await _organisations.doc(userId).get();
    if (!snapshot.exists) return null;
    return OrganisationProfile.fromFirestore(snapshot);
  }

  Future<void> createOrganisationProfile(OrganisationProfile profile) {
    final now = FieldValue.serverTimestamp();
    return _organisations.doc(profile.userId).set({
      ...profile.toMap(),
      'created_at': now,
      'updated_at': now,
    }, SetOptions(merge: true));
  }
}
