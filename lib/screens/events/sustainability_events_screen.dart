import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../mock/mock_data.dart';
import '../../models/sustainability_event.dart';
import '../../repositories/event_repository.dart';
import '../../services/link_launcher_service.dart';

class SustainabilityEventsScreen extends StatelessWidget {
  const SustainabilityEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sustainability Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Public sustainability shoutouts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'EcoLoop shares public event information and links to official details. These are not EcoLoop-hosted events.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
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
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Showing sample events while Firestore is unavailable.',
                        style: TextStyle(color: EcoLoopTheme.mutedText),
                      ),
                    ),
                    ...mockEvents.map((event) => _EventCard(event: event)),
                  ],
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _EmptyEventsState();
              }

              return Column(
                children: snapshot.data!
                    .map((event) => _EventCard(event: event))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final SustainabilityEvent event;

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
                  _EventMeta(icon: Icons.event, label: event.date),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxWidth = (MediaQuery.sizeOf(context).width - 92)
        .clamp(160.0, 320.0)
        .toDouble();

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

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No public event shoutouts found in Firestore yet. Add documents under events to display them here.',
          style: TextStyle(color: EcoLoopTheme.mutedText),
        ),
      ),
    );
  }
}
