import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/completed_product.dart';

class CompletedProductRepository {
  CompletedProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('completed_products');

  Stream<CompletedProduct?> watchProduct(String productId) {
    if (productId.trim().isEmpty) {
      return const Stream<CompletedProduct?>.empty();
    }
    return _products.doc(productId).snapshots().map((document) {
      if (!document.exists) return null;
      return CompletedProduct.fromFirestore(document);
    });
  }

  Stream<List<CompletedProduct>> watchPublishedProducts() {
    return _products
        .where('is_published_to_hub', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .map(CompletedProduct.fromFirestore)
              .toList();
          products.sort((a, b) {
            final aTime = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return products;
        });
  }

  Future<String> createProduct(CompletedProduct product) async {
    final now = FieldValue.serverTimestamp();
    final document = await _products.add({
      ...product.toMap(),
      'created_at': now,
      'submitted_at': now,
      'updated_at': now,
    });
    return document.id;
  }

  Future<void> publishToHub({
    required CompletedProduct product,
    required AppUser creator,
  }) {
    final canShowContact = product.isAvailableForContact;
    return _products.doc(product.id).update({
      'is_published_to_hub': true,
      'visible_creator_name': creator.displayName.trim(),
      'visible_creator_email': canShowContact ? creator.email.trim() : '',
      'visible_creator_phone': canShowContact ? creator.phoneNumber.trim() : '',
      'published_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
