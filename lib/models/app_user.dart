class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.role = AppUserRoles.normalUser,
    this.phoneNumber = '',
    this.photoUrl = '',
    this.preferredState = 'Selangor',
    this.preferredArea = '',
  });

  final String uid;
  final String displayName;
  final String email;
  final String role;
  final String phoneNumber;
  final String photoUrl;
  final String preferredState;
  final String preferredArea;

  bool get isOrganisationUser => role == AppUserRoles.organisationUser;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'preferred_state': preferredState,
      'preferred_area': preferredArea,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: _stringValue(data['uid']),
      displayName: _stringValue(data['display_name']),
      email: _stringValue(data['email']),
      role: _stringValue(data['role'], fallback: AppUserRoles.normalUser),
      phoneNumber: _stringValue(data['phone_number']),
      photoUrl: _stringValue(data['photo_url']),
      preferredState: _stringValue(
        data['preferred_state'],
        fallback: 'Selangor',
      ),
      preferredArea: _stringValue(data['preferred_area']),
    );
  }
}

class AppUserRoles {
  const AppUserRoles._();

  static const normalUser = 'normal_user';
  static const organisationUser = 'organisation_user';
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}
