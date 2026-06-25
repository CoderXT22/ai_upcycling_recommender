class WasteItem {
  const WasteItem({
    required this.object,
    required this.material,
    required this.category,
    this.source = 'manual',
    this.confidence,
  });

  final String object;
  final String material;
  final String category;
  final String source;
  final double? confidence;
}
