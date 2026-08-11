import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/diy_guide.dart';
import '../../models/saved_guide.dart';
import '../../repositories/diy_repository.dart';
import '../../repositories/saved_guide_repository.dart';
import '../../services/auth_service.dart';
import '../diy/diy_guide_detail_screen.dart';

class SavedDiyGuidesScreen extends StatelessWidget {
  const SavedDiyGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved DIY Guides')),
      body: StreamBuilder<List<SavedGuide>>(
        stream: SavedGuideRepository().watchSavedGuides(userId),
        builder: (context, savedSnapshot) {
          if (savedSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final savedGuides = savedSnapshot.data ?? const <SavedGuide>[];
          if (savedGuides.isEmpty) {
            return const _EmptySavedGuides();
          }

          return StreamBuilder<List<DiyGuide>>(
            stream: DiyRepository().watchActiveGuides(),
            builder: (context, guideSnapshot) {
              final guideById = {
                for (final guide in guideSnapshot.data ?? const <DiyGuide>[])
                  guide.id: guide,
              };

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: savedGuides.length,
                itemBuilder: (context, index) {
                  final savedGuide = savedGuides[index];
                  final fullGuide = guideById[savedGuide.guideId];
                  return _SavedGuideCard(
                    savedGuide: savedGuide,
                    fullGuide: fullGuide,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SavedGuideCard extends StatelessWidget {
  const _SavedGuideCard({required this.savedGuide, required this.fullGuide});

  final SavedGuide savedGuide;
  final DiyGuide? fullGuide;

  @override
  Widget build(BuildContext context) {
    final imageUrl = fullGuide?.imageUrl ?? savedGuide.imageUrl;
    final difficulty = fullGuide?.difficultyLevel ?? savedGuide.difficultyLevel;
    final time = fullGuide?.estimatedTime ?? savedGuide.estimatedTime;

    return Card(
      child: ListTile(
        onTap: fullGuide == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DiyGuideDetailScreen(guide: fullGuide!),
                  ),
                );
              },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 54,
            height: 54,
            color: EcoLoopTheme.softGreen,
            child: imageUrl.isEmpty
                ? const Icon(Icons.bookmark, color: EcoLoopTheme.primary)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.bookmark, color: EcoLoopTheme.primary),
                  ),
          ),
        ),
        title: Text(
          savedGuide.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [difficulty, time].where((value) => value.isNotEmpty).join(' - '),
        ),
        trailing: fullGuide == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptySavedGuides extends StatelessWidget {
  const _EmptySavedGuides();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No saved guides yet. Bookmark DIY guides to see them here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: EcoLoopTheme.mutedText),
        ),
      ),
    );
  }
}
