import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contamination_warning.dart';

class ContaminationWarningRepository {
  ContaminationWarningRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<ContaminationWarning>> fetchActiveWarnings() async {
    final snapshot = await _firestore
        .collection('contamination_warnings')
        .get();
    return snapshot.docs
        .map(ContaminationWarning.fromFirestore)
        .where((warning) => warning.isActive)
        .toList();
  }
}
