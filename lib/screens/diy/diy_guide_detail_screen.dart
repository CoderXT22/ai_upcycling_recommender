import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/diy_guide.dart';
import '../../models/project_session.dart';
import '../../repositories/project_image_repository.dart';
import '../../repositories/project_session_repository.dart';
import '../../repositories/saved_guide_repository.dart';
import '../../services/auth_service.dart';
import '../../services/link_launcher_service.dart';
import '../projects/my_projects_screen.dart';

class DiyGuideDetailScreen extends StatefulWidget {
  const DiyGuideDetailScreen({super.key, required this.guide});

  final DiyGuide guide;

  @override
  State<DiyGuideDetailScreen> createState() => _DiyGuideDetailScreenState();
}

class _DiyGuideDetailScreenState extends State<DiyGuideDetailScreen> {
  final _projectSessionRepository = ProjectSessionRepository();
  final _projectImageRepository = ProjectImageRepository();
  bool _isStartingProject = false;

  Future<void> _startProject(String userId) async {
    final choice = await _showBeforePhotoDialog();
    if (choice == null || choice == _BeforePhotoChoice.cancel) return;

    XFile? beforePhoto;
    if (choice == _BeforePhotoChoice.camera ||
        choice == _BeforePhotoChoice.gallery) {
      beforePhoto = await _pickBeforePhoto(
        choice == _BeforePhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (beforePhoto == null) return;
    }

    setState(() => _isStartingProject = true);
    try {
      final sessionId = await _projectSessionRepository.createSession(
        userId: userId,
        guide: widget.guide,
      );

      if (beforePhoto != null) {
        final beforeImageUrl = await _projectImageRepository.uploadBeforePhoto(
          userId: userId,
          sessionId: sessionId,
          image: beforePhoto,
        );
        await _projectSessionRepository.updateBeforePhoto(
          sessionId: sessionId,
          beforeImageUrl: beforeImageUrl,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            beforePhoto == null
                ? 'Project started. You can add before evidence later.'
                : 'Project started with before photo.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to start project: ${error.code}'
                : 'Unable to start project. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingProject = false);
    }
  }

  Future<_BeforePhotoChoice?> _showBeforePhotoDialog() {
    return showDialog<_BeforePhotoChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Project'),
        content: const Text(
          'Before photos improve AI-assisted verification and report credibility. If you skip now, your evidence completeness score may be lower.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BeforePhotoChoice.cancel),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_BeforePhotoChoice.skip),
            icon: const Icon(Icons.skip_next_outlined),
            label: const Text('Skip For Now'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BeforePhotoChoice.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Upload'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BeforePhotoChoice.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  Future<XFile?> _pickBeforePhoto(ImageSource source) async {
    try {
      return ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1400,
      );
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select before photo.')),
      );
      return null;
    }
  }

  void _openMyProjects() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyProjectsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
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
          _ProjectAction(
            userId: userId,
            guide: guide,
            isStartingProject: _isStartingProject,
            onStartProject: userId == null ? null : () => _startProject(userId),
            onOpenMyProjects: _openMyProjects,
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

class _ProjectAction extends StatelessWidget {
  const _ProjectAction({
    required this.userId,
    required this.guide,
    required this.isStartingProject,
    required this.onStartProject,
    required this.onOpenMyProjects,
  });

  final String? userId;
  final DiyGuide guide;
  final bool isStartingProject;
  final VoidCallback? onStartProject;
  final VoidCallback onOpenMyProjects;

  @override
  Widget build(BuildContext context) {
    final currentUserId = userId;
    if (currentUserId == null) {
      return PrimaryButton(
        label: 'Start Project',
        icon: Icons.play_circle_outline,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to start a project.')),
          );
        },
      );
    }

    return StreamBuilder<ProjectSession?>(
      stream: ProjectSessionRepository().watchActiveGuideSession(
        userId: currentUserId,
        guideId: guide.id,
      ),
      builder: (context, snapshot) {
        final activeSession = snapshot.data;
        if (activeSession != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.timelapse_outlined,
                    color: EcoLoopTheme.primary,
                  ),
                  title: const Text(
                    'Project In Progress',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    activeSession.hasBeforePhoto
                        ? 'Before photo saved. Continue from My Projects.'
                        : 'Before photo missing. You can add it when submitting later.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'View My Projects',
                icon: Icons.inventory_2_outlined,
                onPressed: onOpenMyProjects,
              ),
            ],
          );
        }

        return PrimaryButton(
          label: isStartingProject ? 'Starting...' : 'Start Project',
          icon: Icons.play_circle_outline,
          onPressed: isStartingProject ? () {} : onStartProject!,
        );
      },
    );
  }
}

enum _BeforePhotoChoice { camera, gallery, skip, cancel }
