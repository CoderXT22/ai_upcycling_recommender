import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/constants/selangor_areas.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/app_user.dart';
import '../../models/organisation_profile.dart';
import '../../repositories/organisation_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../navigation/main_navigation_screen.dart';
import '../organisations/organisation_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _organisationNameController = TextEditingController();
  final _organisationDescriptionController = TextEditingController();
  final _organisationWebsiteController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _authService = AuthService();
  final _userRepository = UserRepository();
  final _organisationRepository = OrganisationRepository();
  bool _isLoading = false;
  String? _errorMessage;
  String _preferredArea = SelangorAreas.values.first;
  String _accountType = AppUserRoles.normalUser;
  String _organisationType = 'Company';

  bool get _isOrganisationRegistration =>
      _accountType == AppUserRoles.organisationUser;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _organisationNameController.dispose();
    _organisationDescriptionController.dispose();
    _organisationWebsiteController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final validationMessage = _validateForm();
    if (validationMessage != null) {
      setState(() => _errorMessage = validationMessage);
      return;
    }

    final accountType = _accountType;
    final isOrganisationRegistration = _isOrganisationRegistration;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.register(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }
      await _userRepository.createUserProfile(
        AppUser(
          uid: user.uid,
          displayName: _nameController.text.trim(),
          email: user.email ?? _emailController.text.trim(),
          role: accountType,
          phoneNumber: _phoneController.text.trim(),
          preferredArea: _preferredArea,
        ),
      );
      if (isOrganisationRegistration) {
        await _organisationRepository.createOrganisationProfile(
          OrganisationProfile(
            id: user.uid,
            userId: user.uid,
            organisationName: _organisationNameController.text.trim(),
            organisationType: _organisationType,
            description: _organisationDescriptionController.text.trim(),
            email: user.email ?? _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            location: _preferredArea,
            website: _organisationWebsiteController.text.trim(),
            registrationNumber: _registrationNumberController.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isOrganisationRegistration
              ? const OrganisationHomeScreen()
              : const MainNavigationScreen(),
        ),
      );
    } catch (error) {
      setState(() => _errorMessage = _friendlyAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      return _isOrganisationRegistration
          ? 'Enter the contact person name.'
          : 'Enter your full name.';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Enter an email address.';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'Enter a phone number.';
    }
    if (_passwordController.text.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    if (!_isOrganisationRegistration) return null;
    if (_organisationNameController.text.trim().isEmpty) {
      return 'Enter the organisation name.';
    }
    if (_organisationDescriptionController.text.trim().isEmpty) {
      return 'Enter a short organisation description.';
    }
    return null;
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (message.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(),
                const SizedBox(height: 14),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start tracking greener choices',
                  style: TextStyle(color: EcoLoopTheme.mutedText),
                ),
                const SizedBox(height: 28),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: AppUserRoles.normalUser,
                      icon: Icon(Icons.person_outline),
                      label: Text('User'),
                    ),
                    ButtonSegment(
                      value: AppUserRoles.organisationUser,
                      icon: Icon(Icons.business_outlined),
                      label: Text('Organisation'),
                    ),
                  ],
                  selected: {_accountType},
                  onSelectionChanged: (values) {
                    setState(() => _accountType = values.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: _isOrganisationRegistration
                        ? 'Contact person name'
                        : 'Full name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    hintText: 'Email address',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Phone number',
                  ),
                ),
                if (_isOrganisationRegistration) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _organisationNameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.business_outlined),
                      hintText: 'Organisation name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _organisationType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                      labelText: 'Organisation type',
                    ),
                    items:
                        const [
                              'Company',
                              'NGO',
                              'Social enterprise',
                              'School or university',
                              'Recycling centre',
                              'CSR team',
                              'Local council',
                              'Event organiser',
                            ]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _organisationType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _organisationDescriptionController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.description_outlined),
                      hintText: 'Organisation description',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _organisationWebsiteController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link_outlined),
                      hintText: 'Website or official link (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _registrationNumberController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'Registration number (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _preferredArea,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    labelText: 'Selangor area',
                  ),
                  items: SelangorAreas.values
                      .map(
                        (area) =>
                            DropdownMenuItem(value: area, child: Text(area)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _preferredArea = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: 'Password',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _isLoading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(label: 'Register', onPressed: _register),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
