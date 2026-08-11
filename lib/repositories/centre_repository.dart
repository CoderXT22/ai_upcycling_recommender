import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recycling_centre.dart';

class CentreRepository {
  CentreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RecyclingCentre>> watchSelangorCentres() {
    return _firestore
        .collection('recycling_centres')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(RecyclingCentre.fromFirestore)
                  .where(
                    (centre) =>
                        centre.isActive &&
                        centre.state.toLowerCase() == 'selangor',
                  )
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<List<RecyclingCentre>> fetchSelangorCentres() async {
    final snapshot = await _firestore.collection('recycling_centres').get();
    return snapshot.docs
        .map(RecyclingCentre.fromFirestore)
        .where(
          (centre) =>
              centre.isActive && centre.state.toLowerCase() == 'selangor',
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
