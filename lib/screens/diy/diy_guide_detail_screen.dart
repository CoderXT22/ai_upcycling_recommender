import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/diy_guide.dart';
import '../../repositories/completed_guide_repository.dart';
import '../../repositories/saved_guide_repository.dart';
import '../../services/auth_service.dart';
import '../../services/link_launcher_service.dart';

class DiyGuideDetailScreen extends StatelessWidget {
  const DiyGuideDetailScreen({super.key, required this.guide});

  final DiyGuide guide;

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY Guide'),
        actions: [
          if (userId == null)
            IconButton(
              tooltip: 'Save guide',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to save DIY guides.'),
                  ),
                );
              },
              icon: const Icon(Icons.bookmark_border),
            )
          else
            StreamBuilder<Set<String>>(
              stream: SavedGuideRepository().watchSavedGuideIds(userId),
              builder: (context, snapshot) {
                final isSaved = snapshot.data?.contains(guide.id) ?? false;
                return IconButton(
                  tooltip: isSaved ? 'Unsave guide' : 'Save guide',
                  onPressed: () async {
                    await SavedGuideRepository().toggleSavedGuide(
                      userId: userId,
                      guide: guide,
                    );
                  },
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: EcoLoopTheme.softGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: guide.imageUrl.isEmpty
                ? const Icon(
                    Icons.handyman_outlined,
                    size: 56,
                    color: EcoLoopTheme.primary,
                  )
                : Image.network(
                    guide.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.handyman_outlined,
                      size: 56,
                      color: EcoLoopTheme.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            guide.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            guide.description,
            style: const TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(guide.difficultyLevel)),
              Chip(label: Text(guide.estimatedTime)),
              if (guide.hasVideo) Chip(label: Text('${guide.videoType} video')),
            ],
          ),
          if (guide.hasVideo) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: EcoLoopTheme.primary,
                ),
                title: const Text('Tutorial video available'),
                subtitle: Text(guide.videoUrl),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => const LinkLauncherService().openUrl(
                  context,
                  guide.videoUrl,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (userId == null)
            PrimaryButton(
              label: 'Mark as Completed',
              icon: Icons.check_circle_outline,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to mark guides completed.'),
                  ),
                );
              },
            )
          else
            StreamBuilder<bool>(
              stream: CompletedGuideRepository().watchIsCompleted(
                userId: userId,
                guideId: guide.id,
              ),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                return PrimaryButton(
                  label: isCompleted ? 'Completed' : 'Mark as Completed',
                  icon: isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  onPressed: isCompleted
                      ? () async {
                          final shouldUndo = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Undo completion?'),
                              content: Text(
                                'Remove "${guide.title}" from your completed DIY list?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (shouldUndo != true) return;
                          await CompletedGuideRepository().unmarkCompleted(
                            userId: userId,
                            guideId: guide.id,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'DIY guide removed from completed list.',
                              ),
                            ),
                          );
                        }
                      : () async {
                          await CompletedGuideRepository().markCompleted(
                            userId: userId,
                            guide: guide,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('DIY guide marked as completed.'),
                            ),
                          );
                        },
                );
              },
            ),
          const SizedBox(height: 18),
          const Text(
            'Materials',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...guide.materialsNeeded.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Steps',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...guide.steps.indexed.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: EcoLoopTheme.primary,
                child: Text(
                  '${entry.$1 + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(entry.$2),
            ),
          ),
        ],
      ),
    );
  }
}
