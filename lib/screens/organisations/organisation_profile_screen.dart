import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/constants/selangor_areas.dart';
import '../../models/organisation_profile.dart';
import '../../repositories/organisation_repository.dart';
import '../../services/auth_service.dart';

class OrganisationProfileScreen extends StatefulWidget {
  const OrganisationProfileScreen({super.key, this.profile});

  final OrganisationProfile? profile;

  @override
  State<OrganisationProfileScreen> createState() =>
      _OrganisationProfileScreenState();
}

class _OrganisationProfileScreenState extends State<OrganisationProfileScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _registrationController = TextEditingController();
  String _organisationType = 'Company';
  String _location = SelangorAreas.values.first;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    if (profile == null) {
      final user = AuthService().currentUser;
      _emailController.text = user?.email ?? '';
      return;
    }
    _nameController.text = profile.organisationName;
    _descriptionController.text = profile.description;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _websiteController.text = profile.website;
    _registrationController.text = profile.registrationNumber;
    _organisationType = _organisationTypes.contains(profile.organisationType)
        ? profile.organisationType
        : _organisationTypes.first;
    _location = SelangorAreas.values.contains(profile.location)
        ? profile.location
        : SelangorAreas.values.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final validationMessage = _validate();
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await OrganisationRepository().createOrganisationProfile(
        OrganisationProfile(
          id: user.uid,
          userId: user.uid,
          organisationName: _nameController.text.trim(),
          organisationType: _organisationType,
          description: _descriptionController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _location,
          website: _websiteController.text.trim(),
          registrationNumber: _registrationController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation profile saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to save profile: ${error.code}.'
                : 'Unable to save profile. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validate() {
    if (_nameController.text.trim().isEmpty) return 'Enter organisation name.';
    if (_descriptionController.text.trim().isEmpty) {
      return 'Enter organisation description.';
    }
    if (_emailController.text.trim().isEmpty) return 'Enter email.';
    if (_phoneController.text.trim().isEmpty) return 'Enter phone number.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organisation Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Organisation details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'These details are used for event shoutouts and organisation tools.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
          _TextInput(controller: _nameController, label: 'Organisation name'),
          DropdownButtonFormField<String>(
            initialValue: _organisationType,
            decoration: const InputDecoration(
              labelText: 'Organisation type',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _organisationTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _organisationType = value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          _TextInput(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 3,
          ),
          _TextInput(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _TextInput(
            controller: _phoneController,
            label: 'Phone',
            keyboardType: TextInputType.phone,
          ),
          DropdownButtonFormField<String>(
            initialValue: _location,
            decoration: const InputDecoration(
              labelText: 'Selangor area',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: SelangorAreas.values
                .map((area) => DropdownMenuItem(value: area, child: Text(area)))
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value != null) setState(() => _location = value);
                  },
          ),
          const SizedBox(height: 12),
          _TextInput(
            controller: _websiteController,
            label: 'Website or official link (optional)',
            keyboardType: TextInputType.url,
          ),
          _TextInput(
            controller: _registrationController,
            label: 'Registration number (optional)',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
          ),
        ],
      ),
    );
  }
}

const _organisationTypes = [
  'Company',
  'NGO',
  'Social enterprise',
  'School or university',
  'Recycling centre',
  'CSR team',
  'Local council',
  'Event organiser',
];

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
