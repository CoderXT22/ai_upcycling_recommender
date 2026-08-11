import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedProduct {
  const CompletedProduct({
    required this.id,
    required this.userId,
    required this.guideId,
    required this.projectSessionId,
    required this.productName,
    required this.materialsUsed,
    required this.quantityUsed,
    required this.reusedMaterials,
    required this.timeTaken,
    required this.estimatedCost,
    required this.productPurpose,
    required this.condition,
    required this.safetyNote,
    required this.dimensions,
    required this.availableQuantity,
    required this.canProduceMore,
    required this.availabilityType,
    required this.isAvailableForContact,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.expectedPriceOrRange = '',
    this.location = '',
    this.verificationStatus = 'waiting_verification',
    this.assessmentMethod = 'rule_based_evidence_only',
    this.evidenceCompletenessScore = 0,
    this.materialMatchScore,
    this.diyOutputMatchScore,
    this.transformationPlausibilityScore,
    this.imageQualityScore,
    this.finalVerificationScore = 0,
    this.verificationBadge = '',
    this.reportSummary = '',
    this.evidenceSummary = '',
    this.improvementTips = const [],
    this.aiExplanation = '',
    this.isPublishedToHub = false,
    this.visibleCreatorName = '',
    this.visibleCreatorEmail = '',
    this.visibleCreatorPhone = '',
    this.publishedAt,
  });

  final String id;
  final String userId;
  final String guideId;
  final String projectSessionId;
  final String productName;
  final String materialsUsed;
  final String quantityUsed;
  final List<ReusedMaterial> reusedMaterials;
  final String timeTaken;
  final String estimatedCost;
  final String productPurpose;
  final String condition;
  final String safetyNote;
  final String dimensions;
  final String availableQuantity;
  final bool canProduceMore;
  final String availabilityType;
  final bool isAvailableForContact;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String expectedPriceOrRange;
  final String location;
  final String verificationStatus;
  final String assessmentMethod;
  final int evidenceCompletenessScore;
  final int? materialMatchScore;
  final int? diyOutputMatchScore;
  final int? transformationPlausibilityScore;
  final int? imageQualityScore;
  final int finalVerificationScore;
  final String verificationBadge;
  final String reportSummary;
  final String evidenceSummary;
  final List<String> improvementTips;
  final String aiExplanation;
  final bool isPublishedToHub;
  final String visibleCreatorName;
  final String visibleCreatorEmail;
  final String visibleCreatorPhone;
  final DateTime? publishedAt;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'guide_id': guideId,
      'project_session_id': projectSessionId,
      'product_name': productName,
      'materials_used': materialsUsed,
      'quantity_used': quantityUsed,
      'reused_materials': reusedMaterials
          .map((material) => material.toMap())
          .toList(),
      'time_taken': timeTaken,
      'estimated_cost': estimatedCost,
      'product_purpose': productPurpose,
      'condition': condition,
      'safety_note': safetyNote,
      'dimensions': dimensions,
      'available_quantity': availableQuantity,
      'can_produce_more': canProduceMore,
      'availability_type': availabilityType,
      'expected_price_or_range': expectedPriceOrRange,
      'is_available_for_contact': isAvailableForContact,
      'before_image_url': beforeImageUrl,
      'after_image_url': afterImageUrl,
      'location': location,
      'verification_status': verificationStatus,
      'assessment_method': assessmentMethod,
      'evidence_completeness_score': evidenceCompletenessScore,
      'material_match_score': materialMatchScore,
      'diy_output_match_score': diyOutputMatchScore,
      'transformation_plausibility_score': transformationPlausibilityScore,
      'image_quality_score': imageQualityScore,
      'final_verification_score': finalVerificationScore,
      'verification_badge': verificationBadge,
      'report_summary': reportSummary,
      'evidence_summary': evidenceSummary,
      'improvement_tips': improvementTips,
      'ai_explanation': aiExplanation,
      'is_published_to_hub': isPublishedToHub,
      'visible_creator_name': visibleCreatorName,
      'visible_creator_email': visibleCreatorEmail,
      'visible_creator_phone': visibleCreatorPhone,
    };
  }

  factory CompletedProduct.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return CompletedProduct(
      id: document.id,
      userId: _stringValue(data['user_id']),
      guideId: _stringValue(data['guide_id']),
      projectSessionId: _stringValue(data['project_session_id']),
      productName: _stringValue(data['product_name']),
      materialsUsed: _stringValue(data['materials_used']),
      quantityUsed: _stringValue(data['quantity_used']),
      reusedMaterials: _reusedMaterials(data['reused_materials']),
      timeTaken: _stringValue(data['time_taken']),
      estimatedCost: _stringValue(data['estimated_cost']),
      productPurpose: _stringValue(data['product_purpose']),
      condition: _stringValue(data['condition']),
      safetyNote: _stringValue(data['safety_note']),
      dimensions: _stringValue(data['dimensions']),
      availableQuantity: _stringValue(data['available_quantity']),
      canProduceMore: data['can_produce_more'] == true,
      availabilityType: _stringValue(data['availability_type']),
      expectedPriceOrRange: _stringValue(data['expected_price_or_range']),
      isAvailableForContact: data['is_available_for_contact'] == true,
      beforeImageUrl: _stringValue(data['before_image_url']),
      afterImageUrl: _stringValue(data['after_image_url']),
      location: _stringValue(data['location']),
      verificationStatus: _stringValue(
        data['verification_status'],
        fallback: 'waiting_verification',
      ),
      assessmentMethod: _stringValue(
        data['assessment_method'],
        fallback: 'rule_based_evidence_only',
      ),
      evidenceCompletenessScore: _intValue(
        data['evidence_completeness_score'],
      ),
      materialMatchScore: _nullableIntValue(data['material_match_score']),
      diyOutputMatchScore: _nullableIntValue(data['diy_output_match_score']),
      transformationPlausibilityScore: _nullableIntValue(
        data['transformation_plausibility_score'],
      ),
      imageQualityScore: _nullableIntValue(data['image_quality_score']),
      finalVerificationScore: _intValue(data['final_verification_score']),
      verificationBadge: _stringValue(data['verification_badge']),
      reportSummary: _stringValue(data['report_summary']),
      evidenceSummary: _stringValue(data['evidence_summary']),
      improvementTips: _stringList(data['improvement_tips']),
      aiExplanation: _stringValue(data['ai_explanation']),
      isPublishedToHub: data['is_published_to_hub'] == true,
      visibleCreatorName: _stringValue(data['visible_creator_name']),
      visibleCreatorEmail: _stringValue(data['visible_creator_email']),
      visibleCreatorPhone: _stringValue(data['visible_creator_phone']),
      publishedAt: _dateTimeValue(data['published_at']),
    );
  }
}

class ReusedMaterial {
  const ReusedMaterial({required this.material, required this.quantity});

  final String material;
  final int quantity;

  Map<String, dynamic> toMap() {
    return {'material': material, 'quantity': quantity};
  }

  factory ReusedMaterial.fromMap(Map<String, dynamic> data) {
    return ReusedMaterial(
      material: _stringValue(data['material']),
      quantity: _intValue(data['quantity'], fallback: 1),
    );
  }
}

class AvailabilityTypes {
  const AvailabilityTypes._();

  static const donation = 'donation';
  static const sale = 'sale';
  static const collaboration = 'collaboration';
  static const showcaseOnly = 'showcase_only';
  static const csrOrEventUse = 'csr_or_event_use';

  static const values = [
    donation,
    sale,
    collaboration,
    showcaseOnly,
    csrOrEventUse,
  ];
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

int? _nullableIntValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList();
  }
  return const [];
}

List<ReusedMaterial> _reusedMaterials(Object? value) {
  if (value is Iterable) {
    return value
        .whereType<Map>()
        .map((entry) => ReusedMaterial.fromMap(Map<String, dynamic>.from(entry)))
        .where((material) => material.material.isNotEmpty)
        .toList();
  }
  return const [];
}

DateTime? _dateTimeValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
