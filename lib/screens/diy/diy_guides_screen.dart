import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../../models/diy_guide.dart';
import 'diy_guide_detail_screen.dart';

class DiyGuidesScreen extends StatelessWidget {
  const DiyGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        const SectionHeader(title: 'DIY Guides'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search guides...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: const [
              _FilterChip(label: 'Title', selected: true),
              _FilterChip(label: 'Difficulty'),
              _FilterChip(label: 'Time'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...mockDiyGuides.map((guide) => _DiyGuideCard(guide: guide)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

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

class _DiyGuideCard extends StatelessWidget {
  const _DiyGuideCard({required this.guide});

  final DiyGuide guide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiyGuideDetailScreen(guide: guide),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: EcoLoopTheme.softGreen,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.handyman_outlined,
                  size: 44,
                  color: EcoLoopTheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.materialsNeeded.join(', '),
                      style: const TextStyle(
                        color: EcoLoopTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetaPill(guide.difficultyLevel),
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          guide.estimatedTime,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        const Icon(Icons.bookmark_border, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${guide.savedCount} saved',
                      style: const TextStyle(
                        color: EcoLoopTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EcoLoopTheme.softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: EcoLoopTheme.primaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
