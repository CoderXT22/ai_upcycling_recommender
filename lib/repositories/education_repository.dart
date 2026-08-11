import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/education_article.dart';

class EducationRepository {
  EducationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<EducationArticle>> watchActiveArticles() {
    return _firestore
        .collection('education_articles')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(EducationArticle.fromFirestore)
                  .where((article) => article.isActive)
                  .toList()
                ..sort((a, b) => a.title.compareTo(b.title)),
        );
  }
}
