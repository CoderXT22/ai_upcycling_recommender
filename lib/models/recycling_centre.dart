class RecyclingCentre {
  const RecyclingCentre({
    required this.id,
    required this.name,
    required this.address,
    required this.acceptedMaterials,
    required this.operatingHours,
    required this.distance,
    required this.status,
    required this.lastUpdated,
  });

  final String id;
  final String name;
  final String address;
  final List<String> acceptedMaterials;
  final String operatingHours;
  final String distance;
  final String status;
  final String lastUpdated;
}
