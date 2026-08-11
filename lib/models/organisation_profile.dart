import 'package:cloud_firestore/cloud_firestore.dart';

class OrganisationProfile {
  const OrganisationProfile({
    required this.id,
    required this.userId,
    required this.organisationName,
    required this.organisationType,
    required this.description,
    required this.email,
    required this.phone,
    required this.location,
    this.website = '',
    this.registrationNumber = '',
  });

  final String id;
  final String userId;
  final String organisationName;
  final String organisationType;
  final String description;
  final String email;
  final String phone;
  final String location;
  final String website;
  final String registrationNumber;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'organisation_name': organisationName,
      'organisation_type': organisationType,
      'description': description,
      'email': email,
      'phone': phone,
      'location': location,
      'website': website,
      'registration_number': registrationNumber,
    };
  }

  factory OrganisationProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return OrganisationProfile(
      id: snapshot.id,
      userId: _stringValue(data['user_id']),
      organisationName: _stringValue(data['organisation_name']),
      organisationType: _stringValue(data['organisation_type']),
      description: _stringValue(data['description']),
      email: _stringValue(data['email']),
      phone: _stringValue(data['phone']),
      location: _stringValue(data['location']),
      website: _stringValue(data['website']),
      registrationNumber: _stringValue(data['registration_number']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}
