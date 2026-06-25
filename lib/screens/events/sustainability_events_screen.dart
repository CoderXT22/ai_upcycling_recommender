import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../mock/mock_data.dart';
import '../../models/sustainability_event.dart';

class SustainabilityEventsScreen extends StatelessWidget {
  const SustainabilityEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sustainability Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: mockEvents.map((event) => _EventCard(event: event)).toList(),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _EventMeta(icon: Icons.event, label: event.date),
                  _EventMeta(icon: Icons.place_outlined, label: event.location),
                  _EventMeta(
                    icon: Icons.groups_outlined,
                    label: '${event.joinedCount} joined',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Required: ${event.requiredMaterials}',
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new),
                label: const Text('Official Details'),
              ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: EcoLoopTheme.mutedText),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
