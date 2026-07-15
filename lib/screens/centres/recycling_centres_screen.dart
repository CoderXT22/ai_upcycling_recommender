import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../../models/pending_recycling_session.dart';
import '../../models/recycling_centre.dart';
import '../../repositories/centre_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../services/link_launcher_service.dart';
import '../../services/pending_recycling_session_service.dart';

class RecyclingCentresScreen extends StatefulWidget {
  const RecyclingCentresScreen({super.key, this.initialCategory = 'all'});

  final String initialCategory;

  @override
  State<RecyclingCentresScreen> createState() => _RecyclingCentresScreenState();
}

class _RecyclingCentresScreenState extends State<RecyclingCentresScreen>
    with WidgetsBindingObserver {
  late String _selectedCategory;
  bool _activityPromptOpen = false;

  static const _filters = [
    ('All', 'all'),
    ('Plastic', 'plastic'),
    ('Glass', 'glass'),
    ('Metal', 'metal'),
    ('Paper', 'paper'),
    ('Fabric', 'fabric'),
    ('E-Waste', 'electronic_waste'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCategory = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingRecyclingSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingRecyclingSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        const SectionHeader(
          title: 'Recycling Centres',
          subtitle: 'Selangor centres with latest known acceptance info',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: EcoLoopTheme.softGreen,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EcoLoopTheme.border),
            ),
            child: const Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 72,
                    color: EcoLoopTheme.primary,
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: Text(
                    'Selangor centre map preview',
                    style: TextStyle(
                      color: EcoLoopTheme.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: _filters
                .map(
                  (filter) => _MaterialFilter(
                    filter.$1,
                    selected: _selectedCategory == filter.$2,
                    onTap: () => setState(() => _selectedCategory = filter.$2),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<RecyclingCentre>>(
          stream: CentreRepository().watchSelangorCentres(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              final filtered = _filterCentres(mockCentres);
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Showing sample centres while Firestore is unavailable.',
                      style: TextStyle(color: EcoLoopTheme.mutedText),
                    ),
                  ),
                  ...filtered.map(
                    (centre) => _CentreCard(
                      centre: centre,
                      onNavigate: () => _openNavigation(centre),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const _EmptyCentresState();
            }

            final filtered = _filterCentres(snapshot.data!);
            if (filtered.isEmpty) {
              return const _NoMatchingCentresState();
            }

            return Column(
              children: filtered
                  .map(
                    (centre) => _CentreCard(
                      centre: centre,
                      onNavigate: () => _openNavigation(centre),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  List<RecyclingCentre> _filterCentres(List<RecyclingCentre> centres) {
    return centres
        .where((centre) => centre.acceptsCategory(_selectedCategory))
        .toList();
  }

  Future<void> _openNavigation(RecyclingCentre centre) async {
    final shouldOpenMaps = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ready to navigate?'),
        content: const Text(
          'After your drop-off, return to EcoLoop and we will help you log the recycling activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Maps'),
          ),
        ],
      ),
    );

    if (shouldOpenMaps != true || !mounted) return;

    final session = PendingRecyclingSession(
      centreId: centre.id,
      centreName: centre.name,
      materialCategory: _activityCategoryFor(centre),
      startedAt: DateTime.now(),
    );

    try {
      await const PendingRecyclingSessionService().save(session);
    } catch (_) {
      _showMessage(
        'Navigation will open, but EcoLoop could not prepare the activity reminder.',
      );
    }

    if (!mounted) return;
    final opened = await const LinkLauncherService().openMapNavigation(
      context: context,
      name: centre.name,
      address: centre.address,
      latitude: centre.latitude,
      longitude: centre.longitude,
    );

    if (!opened) {
      await const PendingRecyclingSessionService().clear();
    }
  }

  String _activityCategoryFor(RecyclingCentre centre) {
    if (_selectedCategory != 'all') return _selectedCategory;
    return 'unspecified';
  }

  Future<void> _checkPendingRecyclingSession() async {
    if (_activityPromptOpen || !mounted) return;

    final PendingRecyclingSession? session;
    try {
      session = await const PendingRecyclingSessionService().readActive();
    } catch (_) {
      return;
    }

    if (session == null || !mounted) return;
    final activeSession = session;

    _activityPromptOpen = true;
    final shouldLog = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mission check-in'),
        content: Text(
          'Did you complete your recycling drop-off at ${activeSession.centreName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, I recycled'),
          ),
        ],
      ),
    );
    _activityPromptOpen = false;

    if (!mounted) return;
    if (shouldLog == true) {
      await _logRecyclingActivity(activeSession);
      return;
    }

    await const PendingRecyclingSessionService().clear();
  }

  Future<void> _logRecyclingActivity(PendingRecyclingSession session) async {
    final user = AuthService().currentUser;
    if (user == null) {
      _showMessage('Please log in again before saving activity.');
      return;
    }

    try {
      await UserRepository().logRecyclingActivity(
        uid: user.uid,
        centreId: session.centreId,
        centreName: session.centreName,
        materialCategory: session.materialCategory,
      );
      await const PendingRecyclingSessionService().clear();
      _showMessage('Nice work. Your recycling activity has been logged.');
    } catch (_) {
      _showMessage('Unable to log activity right now. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MaterialFilter extends StatelessWidget {
  const _MaterialFilter(
    this.label, {
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: EcoLoopTheme.primary,
        backgroundColor: EcoLoopTheme.softGreen,
        labelStyle: TextStyle(
          color: selected ? Colors.white : EcoLoopTheme.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CentreCard extends StatelessWidget {
  const _CentreCard({required this.centre, required this.onNavigate});

  final RecyclingCentre centre;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      centre.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (centre.distance.isNotEmpty)
                    Text(
                      centre.distance,
                      style: const TextStyle(
                        color: EcoLoopTheme.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _centreTypeLabel(centre.centreType),
                style: const TextStyle(
                  color: EcoLoopTheme.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                centre.address,
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: centre.acceptedMaterials
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(centre.operatingHours)),
                ],
              ),
              if (centre.contactInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.call_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(centre.contactInfo)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Status: ${_statusLabel(centre.status)}'),
                  const Spacer(),
                  Text(
                    centre.lastVerifiedAt.isEmpty
                        ? 'Verification unknown'
                        : 'Verified ${centre.lastVerifiedAt}',
                    style: const TextStyle(
                      color: EcoLoopTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Navigate'),
                  ),
                  if (centre.officialLink.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => const LinkLauncherService().openUrl(
                        context,
                        centre.officialLink,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Official Info'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCentresState extends StatelessWidget {
  const _EmptyCentresState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No Selangor centre data found in Firestore yet. Add documents under recycling_centres to display them here.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
        ),
      ),
    );
  }
}

class _NoMatchingCentresState extends StatelessWidget {
  const _NoMatchingCentresState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No centres match this material filter yet.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
        ),
      ),
    );
  }
}

String _centreTypeLabel(String value) {
  return switch (value) {
    'donation' => 'Donation centre',
    'both' => 'Recycling and donation centre',
    _ => 'Recycling centre',
  };
}

String _statusLabel(String value) {
  return switch (value) {
    'accepting' => 'Accepting',
    'limited' => 'Limited',
    'temporarily_closed' => 'Temporarily closed',
    _ => 'Unknown',
  };
}
