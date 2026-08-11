class AiDetectionResult {
  const AiDetectionResult({
    required this.object,
    required this.material,
    required this.category,
    required this.confidence,
    this.note = '',
  });

  final String object;
  final String material;
  final String category;
  final double confidence;
  final String note;

  int get confidencePercent => (confidence * 100).round();
}
