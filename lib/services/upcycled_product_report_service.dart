import '../models/completed_product.dart';
import '../models/diy_guide.dart';

class UpcycledProductReportDraft {
  const UpcycledProductReportDraft({
    required this.evidenceCompletenessScore,
    required this.finalVerificationScore,
    required this.verificationStatus,
    required this.verificationBadge,
    required this.reportSummary,
    required this.evidenceSummary,
    required this.improvementTips,
  });

  final int evidenceCompletenessScore;
  final int finalVerificationScore;
  final String verificationStatus;
  final String verificationBadge;
  final String reportSummary;
  final String evidenceSummary;
  final List<String> improvementTips;
}

class UpcycledProductReportService {
  const UpcycledProductReportService();

  UpcycledProductReportDraft generateRuleBasedDraft({
    required String productName,
    required String beforeImageUrl,
    required String afterImageUrl,
    required List<ReusedMaterial> reusedMaterials,
    required String productPurpose,
    required String estimatedCost,
    required String timeTaken,
    required String safetyNote,
    required String condition,
    required String dimensions,
    required String availabilityType,
    required DiyGuide? guide,
  }) {
    final evidenceScore = _evidenceCompletenessScore(
      beforeImageUrl: beforeImageUrl,
      afterImageUrl: afterImageUrl,
      reusedMaterials: reusedMaterials,
      productPurpose: productPurpose,
      estimatedCost: estimatedCost,
      timeTaken: timeTaken,
      safetyNote: safetyNote,
    );
    final badge = _badgeForScore(evidenceScore);
    final status = _statusForScore(evidenceScore);
    final materialSummary = reusedMaterials
        .map((material) => '${material.quantity} x ${material.material}')
        .join(', ');
    final guideTitle = guide?.title.trim().isNotEmpty == true
        ? guide!.title.trim()
        : 'the selected DIY guide';
    final guideContext = guide == null
        ? guideTitle
        : '$guideTitle (${guide.difficultyLevel}, ${guide.estimatedTime})';

    return UpcycledProductReportDraft(
      evidenceCompletenessScore: evidenceScore,
      finalVerificationScore: evidenceScore,
      verificationStatus: status,
      verificationBadge: badge,
      evidenceSummary: _evidenceSummary(
        score: evidenceScore,
        beforeImageUrl: beforeImageUrl,
        afterImageUrl: afterImageUrl,
        reusedMaterials: reusedMaterials,
        productPurpose: productPurpose,
        estimatedCost: estimatedCost,
        timeTaken: timeTaken,
        safetyNote: safetyNote,
      ),
      reportSummary:
          '$productName was submitted as an upcycled product based on $guideContext. '
          'The user reported reusing $materialSummary, spending $timeTaken, '
          'with an estimated production cost of $estimatedCost. The product is '
          'described as "$productPurpose", condition "$condition", size "$dimensions", '
          'and availability type "${_availabilityLabel(availabilityType)}". '
          'This preliminary report is based on evidence completeness only; AI visual credibility assessment has not been applied yet.',
      improvementTips: _improvementTips(
        beforeImageUrl: beforeImageUrl,
        afterImageUrl: afterImageUrl,
        reusedMaterials: reusedMaterials,
        productPurpose: productPurpose,
        estimatedCost: estimatedCost,
        timeTaken: timeTaken,
        safetyNote: safetyNote,
      ),
    );
  }

  int _evidenceCompletenessScore({
    required String beforeImageUrl,
    required String afterImageUrl,
    required List<ReusedMaterial> reusedMaterials,
    required String productPurpose,
    required String estimatedCost,
    required String timeTaken,
    required String safetyNote,
  }) {
    var score = 0;
    if (beforeImageUrl.trim().isNotEmpty) score += 20;
    if (afterImageUrl.trim().isNotEmpty) score += 20;
    if (reusedMaterials.any((material) => material.material.trim().isNotEmpty)) {
      score += 10;
    }
    if (reusedMaterials.any((material) => material.quantity > 0)) score += 10;
    if (productPurpose.trim().isNotEmpty) score += 10;
    if (estimatedCost.trim().isNotEmpty) score += 10;
    if (timeTaken.trim().isNotEmpty) score += 10;
    if (safetyNote.trim().isNotEmpty) score += 10;
    return score.clamp(0, 100).toInt();
  }

  String _badgeForScore(int score) {
    if (score >= 80) return 'Evidence Complete';
    if (score >= 60) return 'Partially Complete';
    return 'More Evidence Required';
  }

  String _statusForScore(int score) {
    if (score >= 60) return 'verified';
    return 'need_more_evidence';
  }

  String _evidenceSummary({
    required int score,
    required String beforeImageUrl,
    required String afterImageUrl,
    required List<ReusedMaterial> reusedMaterials,
    required String productPurpose,
    required String estimatedCost,
    required String timeTaken,
    required String safetyNote,
  }) {
    final included = <String>[
      if (beforeImageUrl.trim().isNotEmpty) 'before photo',
      if (afterImageUrl.trim().isNotEmpty) 'after photo',
      if (reusedMaterials.isNotEmpty) 'material and quantity details',
      if (productPurpose.trim().isNotEmpty) 'product purpose',
      if (estimatedCost.trim().isNotEmpty) 'estimated cost',
      if (timeTaken.trim().isNotEmpty) 'time taken',
      if (safetyNote.trim().isNotEmpty) 'safety note',
    ];
    return 'Evidence completeness is $score/100 based on ${included.join(', ')}.';
  }

  List<String> _improvementTips({
    required String beforeImageUrl,
    required String afterImageUrl,
    required List<ReusedMaterial> reusedMaterials,
    required String productPurpose,
    required String estimatedCost,
    required String timeTaken,
    required String safetyNote,
  }) {
    final tips = <String>[];
    if (beforeImageUrl.trim().isEmpty) {
      tips.add('Add a before photo to strengthen transformation evidence.');
    }
    if (afterImageUrl.trim().isEmpty) {
      tips.add('Upload a clear after photo of the completed product.');
    }
    if (reusedMaterials.isEmpty) {
      tips.add('List each reused material with quantity.');
    }
    if (productPurpose.trim().isEmpty) {
      tips.add('Describe the product purpose.');
    }
    if (estimatedCost.trim().isEmpty) {
      tips.add('Add the estimated production cost.');
    }
    if (timeTaken.trim().isEmpty) {
      tips.add('Add the time taken.');
    }
    if (safetyNote.trim().isEmpty) {
      tips.add('Add a safety note for organisation review.');
    }
    if (tips.isEmpty) {
      tips.add('AI visual credibility assessment can be added later for a stronger report.');
    }
    return tips;
  }
}

String _availabilityLabel(String value) {
  return switch (value) {
    AvailabilityTypes.donation => 'Donation',
    AvailabilityTypes.sale => 'Sale',
    AvailabilityTypes.collaboration => 'Collaboration',
    AvailabilityTypes.csrOrEventUse => 'CSR / event use',
    _ => 'Showcase only',
  };
}
