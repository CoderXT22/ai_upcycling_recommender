class SustainabilityEvent {
  const SustainabilityEvent({
    required this.id,
    required this.title,
    required this.organizer,
    required this.description,
    required this.date,
    required this.location,
    required this.requiredMaterials,
    required this.officialLink,
    required this.joinedCount,
  });

  final String id;
  final String title;
  final String organizer;
  final String description;
  final String date;
  final String location;
  final String requiredMaterials;
  final String officialLink;
  final int joinedCount;
}
