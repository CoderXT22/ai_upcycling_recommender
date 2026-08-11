import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diy_guide.dart';

class DiyRepository {
  DiyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<DiyGuide>> watchActiveGuides() {
    return _firestore
        .collection('diy_guides')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(DiyGuide.fromFirestore).toList()
                ..sort((a, b) => a.title.compareTo(b.title)),
        );
  }

  Future<List<DiyGuide>> fetchActiveGuides() async {
    final snapshot = await _firestore.collection('diy_guides').get();
    return snapshot.docs
        .map(DiyGuide.fromFirestore)
        .where((guide) => guide.isActive)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<DiyGuide?> fetchGuideById(String guideId) async {
    if (guideId.trim().isEmpty) return null;
    final document = await _firestore.collection('diy_guides').doc(guideId).get();
    if (!document.exists) return null;
    final guide = DiyGuide.fromFirestore(document);
    return guide.isActive ? guide : null;
  }
}
