import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/organisation_profile.dart';
import '../../models/sustainability_event.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/organisation_repository.dart';
import '../../services/auth_service.dart';
import '../../services/link_launcher_service.dart';
import 'organisation_profile_screen.dart';

enum _OrganisationEventFilter { all, posted, past }

class OrganisationEventsScreen extends StatefulWidget {
  const OrganisationEventsScreen({super.key});

  @override
  State<OrganisationEventsScreen> createState() =>
      _OrganisationEventsScreenState();
}

class _OrganisationEventsScreenState extends State<OrganisationEventsScreen> {
  _OrganisationEventFilter _filter = _OrganisationEventFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return StreamBuilder<OrganisationProfile?>(
      stream: OrganisationRepository().watchOrganisationForUser(user.uid),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final isProfileLoading =
            profileSnapshot.connectionState == ConnectionState.waiting;
        return Scaffold(
          appBar: AppBar(title: const Text('Sustainability Events')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isProfileLoading
                ? null
                : () {
                    if (profile == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrganisationProfileScreen(),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateOrganisationEventScreen(
                          profile: profile,
                        ),
                      ),
                    );
            },
            icon: isProfileLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(profile == null && !isProfileLoading
                ? 'Set Up Profile'
                : 'Create Event'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Organisation event shoutouts',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create public sustainability events that normal users can discover in the Events screen.',
                style: TextStyle(color: EcoLoopTheme.mutedText),
              ),
              if (isProfileLoading) ...[
                const SizedBox(height: 12),
                const _EventMessage(
                  title: 'Loading organisation details',
                  message: 'Please wait while we check your profile.',
                ),
              ] else if (profile == null) ...[
                const SizedBox(height: 12),
                const _EventMessage(
                  title: 'Set up organisation profile',
                  message: 'Add organisation details once, then create public event shoutouts.',
                ),
              ],
              const SizedBox(height: 16),
              _EventFilterChips(
                selectedFilter: _filter,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<SustainabilityEvent>>(
                stream: EventRepository().watchActiveEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _EventMessage(
                      title: 'Unable to load events',
                      message: snapshot.error is FirebaseException
                          ? 'Firebase error: ${(snapshot.error as FirebaseException).code}.'
                          : 'Please check your connection and try again.',
                    );
                  }

                  final events = snapshot.data ?? const <SustainabilityEvent>[];
                  final filteredEvents = _filteredEvents(events, user.uid);
                  if (filteredEvents.isEmpty) {
                    return const _EventMessage(
                      title: 'No matching events',
                      message: 'Try another filter or create a new event shoutout.',
                    );
                  }

                  return Column(
                    children: filteredEvents
                        .map(
                          (event) => _OrganisationEventCard(
                            event: event,
                            profile: profile,
                            showPastActions:
                                _filter == _OrganisationEventFilter.past &&
                                event.isOwnedBy(user.uid),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<SustainabilityEvent> _filteredEvents(
    List<SustainabilityEvent> events,
    String userId,
  ) {
    switch (_filter) {
      case _OrganisationEventFilter.all:
        return events;
      case _OrganisationEventFilter.posted:
        return events.where((event) => event.isOwnedBy(userId)).toList();
      case _OrganisationEventFilter.past:
        return events
            .where((event) => event.isOwnedBy(userId) && event.isPast)
            .toList();
    }
  }
}

class CreateOrganisationEventScreen extends StatefulWidget {
  const CreateOrganisationEventScreen({
    super.key,
    required this.profile,
    this.event,
  });

  final OrganisationProfile profile;
  final SustainabilityEvent? event;

  @override
  State<CreateOrganisationEventScreen> createState() =>
      _CreateOrganisationEventScreenState();
}

class _CreateOrganisationEventScreenState
    extends State<CreateOrganisationEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _benefitController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _materialsController = TextEditingController();
  final _officialLinkController = TextEditingController();
  final _imageUrlController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isRepublishing = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event == null) return;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _benefitController.text = event.benefit;
    _locationController.text = event.locationName;
    _addressController.text = event.address;
    _materialsController.text = event.requiredMaterials.join(', ');
    _officialLinkController.text = event.officialLink;
    _imageUrlController.text = event.imageUrl;
    _startDate = event.startDate;
    _endDate = event.rawEndDate ?? event.startDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _benefitController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _materialsController.dispose();
    _officialLinkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final currentValue = isStartDate ? _startDate : _endDate;
    final today = DateTime(now.year, now.month, now.day);
    final normalFirstDate = isStartDate ? today : _startDate ?? today;
    final initialDate = currentValue ?? _startDate ?? today;
    final earliestDate = initialDate.isBefore(normalFirstDate)
        ? initialDate
        : normalFirstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliestDate,
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isStartDate) {
        _startDate = picked;
        if (_endDate == null || _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _saveEvent({bool republish = false}) async {
    final validationMessage = _validate();
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }

    setState(() {
      if (republish) {
        _isRepublishing = true;
      } else {
        _isSaving = true;
      }
    });
    try {
      if (_isEditing) {
        await EventRepository().updateOrganisationEvent(
          eventId: widget.event!.id,
          organisationUserId: widget.profile.userId,
          organiser: widget.profile.organisationName,
          title: _titleController.text,
          description: _descriptionController.text,
          benefit: _benefitController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          locationName: _locationController.text,
          address: _addressController.text,
          requiredMaterials: _materials(),
          officialLink: _officialLinkController.text,
          imageUrl: _imageUrlController.text,
        );
      } else {
        await EventRepository().createOrganisationEvent(
          organisationUserId: widget.profile.userId,
          organiser: widget.profile.organisationName,
          title: _titleController.text,
          description: _descriptionController.text,
          benefit: _benefitController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          locationName: _locationController.text,
          address: _addressController.text,
          requiredMaterials: _materials(),
          officialLink: _officialLinkController.text,
          imageUrl: _imageUrlController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            republish
                ? 'Event republished.'
                : _isEditing
                    ? 'Event shoutout updated.'
                    : 'Event shoutout created.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to save event: ${error.code}.'
                : 'Unable to save event. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isRepublishing = false;
        });
      }
    }
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) return 'Enter event title.';
    if (_descriptionController.text.trim().isEmpty) {
      return 'Enter event description.';
    }
    if (_startDate == null) return 'Select event start date.';
    if (_endDate == null) return 'Select event end date.';
    if (_endDate!.isBefore(_startDate!)) {
      return 'End date cannot be before start date.';
    }
    if (_locationController.text.trim().isEmpty) {
      return 'Enter location name.';
    }
    if (_addressController.text.trim().isEmpty) return 'Enter address.';
    if (_materials().isEmpty) {
      return 'Enter at least one required material.';
    }
    if (_officialLinkController.text.trim().isEmpty) {
      return 'Enter official details link.';
    }
    return null;
  }

  List<String> _materials() {
    return _materialsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final startDateText = _startDate == null
        ? 'Select start date'
        : _dateText(_startDate!);
    final endDateText = _endDate == null ? 'Select end date' : _dateText(_endDate!);

    final isBusy = _isSaving || _isRepublishing;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Event' : 'Create Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Public event shoutout',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Organizer: ${widget.profile.organisationName}',
            style: const TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
          _TextInput(controller: _titleController, label: 'Event title'),
          _TextInput(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 4,
          ),
          _TextInput(
            controller: _benefitController,
            label: 'Benefit or incentive (optional)',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(startDateText),
            subtitle: const Text('Start date'),
            trailing: const Icon(Icons.chevron_right),
            onTap: isBusy ? null : () => _pickDate(isStartDate: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_outlined),
            title: Text(endDateText),
            subtitle: const Text('End date'),
            trailing: const Icon(Icons.chevron_right),
            onTap: isBusy ? null : () => _pickDate(isStartDate: false),
          ),
          _TextInput(controller: _locationController, label: 'Location name'),
          _TextInput(controller: _addressController, label: 'Address'),
          _TextInput(
            controller: _materialsController,
            label: 'Required materials',
            hint: 'e.g. plastic bottles, cardboard',
          ),
          _TextInput(
            controller: _officialLinkController,
            label: 'Official details link',
            keyboardType: TextInputType.url,
          ),
          _TextInput(
            controller: _imageUrlController,
            label: 'Image URL (optional)',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isBusy ? null : () => _saveEvent(),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_outlined),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : _isEditing
                      ? 'Save Changes'
                      : 'Create Event',
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _saveEvent(republish: true),
              icon: _isRepublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_outlined),
              label: Text(
                _isRepublishing ? 'Republishing...' : 'Republish Event',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _dateText(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

class _OrganisationEventCard extends StatelessWidget {
  const _OrganisationEventCard({
    required this.event,
    required this.profile,
    required this.showPastActions,
  });

  final SustainabilityEvent event;
  final OrganisationProfile? profile;
  final bool showPastActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl.isNotEmpty) ...[
                Container(
                  height: 130,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: EcoLoopTheme.softGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.event_outlined,
                      color: EcoLoopTheme.primary,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (event.isPast) ...[
                const SizedBox(height: 6),
                const Chip(label: Text('Past Event')),
              ],
              const SizedBox(height: 3),
              Text(
                event.organizer,
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 8),
              Text(event.description),
              if (event.benefit.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EcoLoopTheme.softGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.redeem_outlined,
                        size: 18,
                        color: EcoLoopTheme.primaryDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Benefit: ${event.benefit}',
                          style: const TextStyle(
                            color: EcoLoopTheme.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _EventMeta(icon: Icons.event_outlined, label: event.dateText),
                  if (event.displayLocation.isNotEmpty)
                    _EventMeta(
                      icon: Icons.place_outlined,
                      label: event.displayLocation,
                    ),
                  _EventMeta(
                    icon: Icons.groups_outlined,
                    label: '${event.joinedCount} interested',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Required: ${event.requiredMaterialsText}',
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              if (event.officialLink.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => const LinkLauncherService().openUrl(
                      context,
                      event.officialLink,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Official Details'),
                  ),
                ),
              ],
              if (showPastActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: profile == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreateOrganisationEventScreen(
                                      profile: profile!,
                                      event: event,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('This will remove "${event.title}" from the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    try {
      await EventRepository().deleteOrganisationEvent(event.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to delete event: ${error.code}.'
                : 'Unable to delete event. Please try again.',
          ),
        ),
      );
    }
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        (MediaQuery.sizeOf(context).width - 92).clamp(160.0, 320.0).toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: EcoLoopTheme.mutedText),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventFilterChips extends StatelessWidget {
  const _EventFilterChips({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _OrganisationEventFilter selectedFilter;
  final ValueChanged<_OrganisationEventFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selectedFilter == _OrganisationEventFilter.all,
          onSelected: (_) => onSelected(_OrganisationEventFilter.all),
        ),
        ChoiceChip(
          label: const Text('Posted'),
          selected: selectedFilter == _OrganisationEventFilter.posted,
          onSelected: (_) => onSelected(_OrganisationEventFilter.posted),
        ),
        ChoiceChip(
          label: const Text('Past'),
          selected: selectedFilter == _OrganisationEventFilter.past,
          onSelected: (_) => onSelected(_OrganisationEventFilter.past),
        ),
      ],
    );
  }
}

class _EventMessage extends StatelessWidget {
  const _EventMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: EcoLoopTheme.mutedText)),
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
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
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
