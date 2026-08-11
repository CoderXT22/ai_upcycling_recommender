import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<AppUser?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser.fromMap(data);
    });
  }

  Future<AppUser?> fetchUserProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<void> createUserProfile(AppUser user) {
    final now = FieldValue.serverTimestamp();

    return _users.doc(user.uid).set({
      ...user.toMap(),
      'created_at': now,
      'updated_at': now,
      'last_login_at': now,
    }, SetOptions(merge: true));
  }

  Future<void> updateLastLogin(String uid) {
    return _users.doc(uid).set({
      'last_login_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
    required String phoneNumber,
    required String preferredArea,
  }) {
    return _users.doc(uid).set({
      'display_name': displayName.trim(),
      'phone_number': phoneNumber.trim(),
      'preferred_state': 'Selangor',
      'preferred_area': preferredArea,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logRecyclingActivity({
    required String uid,
    required String centreId,
    required String centreName,
    required String materialCategory,
  }) {
    return _users.doc(uid).collection('recycling_activities').add({
      'centre_id': centreId,
      'centre_name': centreName,
      'material_category': materialCategory,
      'recycled_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchCompletedGuideCount(String uid) {
    return _users
        .doc(uid)
        .collection('completed_guides')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> watchRecyclingActivityCount(String uid) {
    return _users
        .doc(uid)
        .collection('recycling_activities')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
