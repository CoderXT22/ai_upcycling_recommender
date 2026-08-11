class PendingRecyclingSession {
  const PendingRecyclingSession({
    required this.centreId,
    required this.centreName,
    required this.materialCategory,
    required this.startedAt,
  });

  final String centreId;
  final String centreName;
  final String materialCategory;
  final DateTime startedAt;

  Map<String, dynamic> toMap() {
    return {
      'centre_id': centreId,
      'centre_name': centreName,
      'material_category': materialCategory,
      'started_at': startedAt.toIso8601String(),
    };
  }

  factory PendingRecyclingSession.fromMap(Map<String, dynamic> data) {
    return PendingRecyclingSession(
      centreId: _stringValue(data['centre_id']),
      centreName: _stringValue(data['centre_name']),
      materialCategory: _stringValue(data['material_category']),
      startedAt:
          DateTime.tryParse(_stringValue(data['started_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isExpired {
    return DateTime.now().difference(startedAt) > const Duration(hours: 24);
  }
}

String _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return '';
}
