class DiyGuide {
  const DiyGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.materialTags,
    required this.materialsNeeded,
    required this.steps,
    required this.difficultyLevel,
    required this.estimatedTime,
    required this.savedCount,
  });

  final String id;
  final String title;
  final String description;
  final List<String> materialTags;
  final List<String> materialsNeeded;
  final List<String> steps;
  final String difficultyLevel;
  final String estimatedTime;
  final int savedCount;
}
