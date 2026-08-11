import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/disposal_guide.dart';

class DisposalGuideRepository {
  DisposalGuideRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<DisposalGuide>> fetchActiveGuides() async {
    final snapshot = await _firestore.collection('disposal_guides').get();
    return snapshot.docs
        .map(DisposalGuide.fromFirestore)
        .where((guide) => guide.isActive)
        .toList();
  }
}
