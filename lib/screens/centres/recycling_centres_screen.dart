import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../../models/recycling_centre.dart';

class RecyclingCentresScreen extends StatelessWidget {
  const RecyclingCentresScreen({super.key});

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
                    'Map preview placeholder',
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
            children: const [
              _MaterialFilter('Plastic', selected: true),
              _MaterialFilter('Glass'),
              _MaterialFilter('Metal'),
              _MaterialFilter('Paper'),
              _MaterialFilter('Fabric'),
              _MaterialFilter('E-Waste'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...mockCentres.map((centre) => _CentreCard(centre: centre)),
      ],
    );
  }
}

class _MaterialFilter extends StatelessWidget {
  const _MaterialFilter(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? EcoLoopTheme.primary
            : EcoLoopTheme.softGreen,
        labelStyle: TextStyle(
          color: selected ? Colors.white : EcoLoopTheme.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CentreCard extends StatelessWidget {
  const _CentreCard({required this.centre});

  final RecyclingCentre centre;

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
                  Text(
                    centre.distance,
                    style: const TextStyle(
                      color: EcoLoopTheme.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Status: ${centre.status}'),
                  const Spacer(),
                  Text(
                    'Updated ${centre.lastUpdated}',
                    style: const TextStyle(
                      color: EcoLoopTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Open Navigation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
