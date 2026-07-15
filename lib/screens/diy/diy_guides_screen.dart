import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../../models/diy_guide.dart';
import '../../repositories/diy_repository.dart';
import '../../repositories/saved_guide_repository.dart';
import '../../services/auth_service.dart';
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
        StreamBuilder<List<DiyGuide>>(
          stream: DiyRepository().watchActiveGuides(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final guides = snapshot.hasData && snapshot.data!.isNotEmpty
                ? snapshot.data!
                : mockDiyGuides;

            if (snapshot.hasError) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Showing sample guides while Firestore is unavailable.',
                      style: TextStyle(color: EcoLoopTheme.mutedText),
                    ),
                  ),
                  ...guides.map((guide) => _DiyGuideCard(guide: guide)),
                ],
              );
            }

            final userId = AuthService().currentUser?.uid;
            if (userId == null) {
              return Column(
                children: guides
                    .map((guide) => _DiyGuideCard(guide: guide))
                    .toList(),
              );
            }

            return StreamBuilder<Set<String>>(
              stream: SavedGuideRepository().watchSavedGuideIds(userId),
              builder: (context, savedSnapshot) {
                final savedGuideIds = savedSnapshot.data ?? const <String>{};
                return Column(
                  children: guides
                      .map(
                        (guide) => _DiyGuideCard(
                          guide: guide,
                          userId: userId,
                          isSaved: savedGuideIds.contains(guide.id),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
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
  const _DiyGuideCard({required this.guide, this.userId, this.isSaved = false});

  final DiyGuide guide;
  final String? userId;
  final bool isSaved;

  Future<void> _toggleSaved(BuildContext context) async {
    final currentUserId = userId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save DIY guides.')),
      );
      return;
    }

    await SavedGuideRepository().toggleSavedGuide(
      userId: currentUserId,
      guide: guide,
    );
  }

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
                child: guide.imageUrl.isEmpty
                    ? const Icon(
                        Icons.handyman_outlined,
                        size: 44,
                        color: EcoLoopTheme.primary,
                      )
                    : Image.network(
                        guide.imageUrl,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.handyman_outlined,
                          size: 44,
                          color: EcoLoopTheme.primary,
                        ),
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
                        if (guide.hasVideo) ...[
                          const Icon(Icons.play_circle_outline, size: 14),
                          const SizedBox(width: 4),
                          const Text('Video', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          guide.estimatedTime,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: isSaved ? 'Unsave guide' : 'Save guide',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _toggleSaved(context),
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved
                                ? EcoLoopTheme.primary
                                : EcoLoopTheme.mutedText,
                          ),
                        ),
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
