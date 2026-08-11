import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../app/app_theme.dart';
import '../../models/project_session.dart';
import '../../repositories/completed_guide_repository.dart';
import '../../repositories/project_session_repository.dart';
import '../../services/auth_service.dart';
import 'completed_product_submission_screen.dart';
import 'upcycled_product_report_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  String _selectedStatus = ProjectSessionStatuses.inProgress;

  static const _statuses = [
    (
      'In Progress',
      ProjectSessionStatuses.inProgress,
      Icons.timelapse_outlined,
    ),
    (
      'Completed',
      ProjectSessionStatuses.completedPrivate,
      Icons.check_circle_outline,
    ),
    (
      'Waiting Verification',
      ProjectSessionStatuses.waitingVerification,
      Icons.hourglass_top_outlined,
    ),
    ('Verified', ProjectSessionStatuses.verified, Icons.verified_outlined),
    ('Published', ProjectSessionStatuses.published, Icons.public_outlined),
    (
      'Need More Evidence',
      ProjectSessionStatuses.needMoreEvidence,
      Icons.error_outline,
    ),
  ];

  Future<void> _completeProject(ProjectSession session) async {
    final wantsReport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Project'),
        content: const Text(
          'Do you want to create an AI-assisted upcycled product report for possible organisation showcase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Mark Completed'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Create Report'),
          ),
        ],
      ),
    );

    if (wantsReport == null || !mounted) return;

    if (wantsReport) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompletedProductSubmissionScreen(session: session),
        ),
      );
      return;
    }

    try {
      await ProjectSessionRepository().markCompletedPrivate(session.id);
      await CompletedGuideRepository().markCompletedFromSession(
        userId: session.userId,
        session: session,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project marked as completed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to complete project: ${error.code}'
                : 'Unable to complete project. Please try again.',
          ),
        ),
      );
    }
  }

  void _openReport(ProjectSession session) {
    if (session.submissionId.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            UpcycledProductReportScreen(productId: session.submissionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Projects')),
      body: StreamBuilder<List<ProjectSession>>(
        stream: ProjectSessionRepository().watchUserSessions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ProjectMessage(
              title: 'Unable to load projects',
              message: _projectLoadErrorMessage(snapshot.error),
            );
          }

          final sessions = snapshot.data ?? const <ProjectSession>[];
          final filtered = sessions
              .where((session) => session.status == _selectedStatus)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Track upcycling projects',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Started projects, verification status, and impact reports will appear here.',
                style: TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _statuses
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status.$1),
                            selected: _selectedStatus == status.$2,
                            onSelected: (_) {
                              setState(() => _selectedStatus = status.$2);
                            },
                            selectedColor: EcoLoopTheme.primary,
                            backgroundColor: EcoLoopTheme.softGreen,
                            labelStyle: TextStyle(
                              color: _selectedStatus == status.$2
                                  ? Colors.white
                                  : EcoLoopTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                const _ProjectMessage(
                  title: 'No projects yet',
                  message: 'Open a DIY guide and tap Start Project.',
                )
              else if (filtered.isEmpty)
                _ProjectMessage(
                  title: 'No ${_statusLabel(_selectedStatus)} projects',
                  message: 'Projects with this status will appear here.',
                )
              else
                ...filtered.map(
                  (session) => _ProjectCard(
                    session: session,
                    onComplete: () => _completeProject(session),
                    onOpenReport: () => _openReport(session),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.session,
    required this.onComplete,
    required this.onOpenReport,
  });

  final ProjectSession session;
  final VoidCallback onComplete;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: EcoLoopTheme.softGreen,
            child: session.guideImageUrl.isEmpty
                ? const Icon(
                    Icons.handyman_outlined,
                    size: 44,
                    color: EcoLoopTheme.primary,
                  )
                : Image.network(
                    session.guideImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.handyman_outlined,
                      size: 44,
                      color: EcoLoopTheme.primary,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.guideTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(session.statusLabel),
                    _StatusPill(
                      session.hasBeforePhoto
                          ? 'Before photo saved'
                          : 'Before photo missing',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session.startedAtText,
                  style: const TextStyle(color: EcoLoopTheme.mutedText),
                ),
                const SizedBox(height: 12),
                _ProjectActionButton(
                  session: session,
                  onComplete: onComplete,
                  onOpenReport: onOpenReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectActionButton extends StatelessWidget {
  const _ProjectActionButton({
    required this.session,
    required this.onComplete,
    required this.onOpenReport,
  });

  final ProjectSession session;
  final VoidCallback onComplete;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    if (session.status == ProjectSessionStatuses.inProgress) {
      return FilledButton.icon(
        onPressed: onComplete,
        icon: const Icon(Icons.task_alt_outlined),
        label: const Text('Complete Project'),
      );
    }

    if (session.status == ProjectSessionStatuses.completedPrivate) {
      return const Text(
        'Completed privately. No report generated.',
        style: TextStyle(color: EcoLoopTheme.mutedText),
      );
    }

    if (session.status == ProjectSessionStatuses.waitingVerification) {
      return const Text(
        'Submission saved. Waiting for AI-assisted verification.',
        style: TextStyle(color: EcoLoopTheme.mutedText),
      );
    }

    if (session.status == ProjectSessionStatuses.verified ||
        session.status == ProjectSessionStatuses.needMoreEvidence ||
        session.status == ProjectSessionStatuses.published) {
      if (session.submissionId.trim().isEmpty) {
        return const Text(
          'Report generated, but the report link is missing.',
          style: TextStyle(color: EcoLoopTheme.mutedText),
        );
      }
      return FilledButton.icon(
        onPressed: onOpenReport,
        icon: const Icon(Icons.description_outlined),
        label: const Text('View Report'),
      );
    }

    return const Text(
      'Report progress will appear here.',
      style: TextStyle(color: EcoLoopTheme.mutedText),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

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
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProjectMessage extends StatelessWidget {
  const _ProjectMessage({required this.title, required this.message});

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

String _statusLabel(String status) {
  return switch (status) {
    ProjectSessionStatuses.completedPrivate => 'completed',
    ProjectSessionStatuses.waitingVerification => 'waiting verification',
    ProjectSessionStatuses.verified => 'verified',
    ProjectSessionStatuses.published => 'published',
    ProjectSessionStatuses.needMoreEvidence => 'need more evidence',
    _ => 'in progress',
  };
}

String _projectLoadErrorMessage(Object? error) {
  if (error is FirebaseException) {
    return 'Firebase error: ${error.code}.';
  }
  return 'Please check your connection and try again.';
}
