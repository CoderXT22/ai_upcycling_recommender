import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/completed_product.dart';
import '../../repositories/completed_product_repository.dart';
import '../../repositories/project_session_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/ai_upcycled_verification_service.dart';
import '../../services/auth_service.dart';

class UpcycledProductReportScreen extends StatefulWidget {
  const UpcycledProductReportScreen({super.key, required this.productId});

  final String productId;

  @override
  State<UpcycledProductReportScreen> createState() =>
      _UpcycledProductReportScreenState();
}

class _UpcycledProductReportScreenState
    extends State<UpcycledProductReportScreen> {
  bool _isPublishing = false;
  bool _isAssessing = false;

  Future<void> _publishToHub(CompletedProduct product) async {
    final canPublish = product.finalVerificationScore >= 60;
    if (!canPublish) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('More evidence is required before publishing.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish to Organisation Hub?'),
        content: Text(
          product.isAvailableForContact
              ? 'Organisation users will be able to view this report and your visible contact details.'
              : 'Organisation users will be able to view this report, but your direct contact details will stay hidden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isPublishing = true);
    try {
      final userId = AuthService().currentUser?.uid;
      if (userId == null) throw StateError('missing-user');
      final creator = await UserRepository().fetchUserProfile(userId);
      if (creator == null) throw StateError('missing-profile');

      await CompletedProductRepository().publishToHub(
        product: product,
        creator: creator,
      );
      await ProjectSessionRepository().markPublished(product.projectSessionId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Published to Organisation Hub.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to publish: ${error.code}.'
                : 'Unable to publish. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _runAiAssessment(CompletedProduct product) async {
    setState(() => _isAssessing = true);
    try {
      final result = await const AiUpcycledVerificationService().verifyProduct(
        product.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI assessment complete. Score: ${result.finalVerificationScore}/100.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseFunctionsException
                ? 'AI assessment failed: ${error.code}.'
                : 'AI assessment failed. Please try again later.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAssessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Impact Report')),
      body: StreamBuilder<CompletedProduct?>(
        stream: CompletedProductRepository().watchProduct(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ReportMessage(
              title: 'Unable to load report',
              message: snapshot.error is FirebaseException
                  ? 'Firebase error: ${(snapshot.error as FirebaseException).code}.'
                  : 'Please check your connection and try again.',
            );
          }

          final product = snapshot.data;
          if (product == null) {
            return const _ReportMessage(
              title: 'Report not found',
              message: 'The report may not have been generated yet.',
            );
          }

          final isOwner = currentUserId == product.userId;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ScoreHeader(product: product),
              const SizedBox(height: 14),
              _Section(
                title: 'Report Summary',
                child: Text(product.reportSummary),
              ),
              _Section(
                title: 'Evidence Completeness',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.evidenceSummary),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: product.evidenceCompletenessScore / 100,
                      minHeight: 8,
                      backgroundColor: EcoLoopTheme.softGreen,
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Evidence Images',
                child: _EvidenceImages(product: product),
              ),
              _Section(
                title: 'Reused Materials',
                child: Column(
                  children: product.reusedMaterials
                      .map(
                        (material) => _FactRow(
                          label: material.material,
                          value: 'Quantity ${material.quantity}',
                        ),
                      )
                      .toList(),
                ),
              ),
              _Section(
                title: 'Product Details',
                child: Column(
                  children: [
                    _FactRow(label: 'Purpose', value: product.productPurpose),
                    _FactRow(label: 'Time', value: product.timeTaken),
                    _FactRow(label: 'Cost', value: product.estimatedCost),
                    _FactRow(label: 'Condition', value: product.condition),
                    _FactRow(label: 'Dimensions', value: product.dimensions),
                    _FactRow(
                      label: 'Available quantity',
                      value: product.availableQuantity,
                    ),
                    _FactRow(
                      label: 'Availability',
                      value: _availabilityLabel(product.availabilityType),
                    ),
                    if (product.expectedPriceOrRange.isNotEmpty)
                      _FactRow(
                        label: 'Expected price',
                        value: product.expectedPriceOrRange,
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Safety Note',
                child: Text(product.safetyNote),
              ),
              _AiAssessmentSection(
                product: product,
                isOwner: isOwner,
                isAssessing: _isAssessing,
                onRunAssessment: () => _runAiAssessment(product),
              ),
              if (isOwner) _PublishSection(
                product: product,
                isPublishing: _isPublishing,
                onPublish: () => _publishToHub(product),
              ),
              if (product.isPublishedToHub) _ContactSection(product: product),
              _Section(
                title: 'Improve Report',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: product.improvementTips
                      .map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                size: 18,
                                color: EcoLoopTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.product});

  final CompletedProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: EcoLoopTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${product.finalVerificationScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '/100',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderPill(product.verificationBadge),
                const _HeaderPill('Rule-based evidence only'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _EvidenceImages extends StatelessWidget {
  const _EvidenceImages({required this.product});

  final CompletedProduct product;

  @override
  Widget build(BuildContext context) {
    final images = [
      if (product.beforeImageUrl.isNotEmpty)
        _EvidenceImageData(label: 'Before', url: product.beforeImageUrl),
      if (product.afterImageUrl.isNotEmpty)
        _EvidenceImageData(label: 'After', url: product.afterImageUrl),
    ];

    if (images.isEmpty) {
      return const Text(
        'No evidence images are available.',
        style: TextStyle(color: EcoLoopTheme.mutedText),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth >= 420
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth.clamp(0, 210).toDouble();
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: images
              .map(
                (image) => SizedBox(
                  width: tileWidth,
                  child: _EvidenceImageTile(image: image),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EvidenceImageData {
  const _EvidenceImageData({required this.label, required this.url});

  final String label;
  final String url;
}

class _EvidenceImageTile extends StatelessWidget {
  const _EvidenceImageTile({required this.image});

  final _EvidenceImageData image;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showImagePreview(context, image),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: EcoLoopTheme.softGreen,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: EcoLoopTheme.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            image.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, _EvidenceImageData image) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text('${image.label} Image')),
          backgroundColor: Colors.black,
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                image.url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishSection extends StatelessWidget {
  const _PublishSection({
    required this.product,
    required this.isPublishing,
    required this.onPublish,
  });

  final CompletedProduct product;
  final bool isPublishing;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final canPublish = product.finalVerificationScore >= 60;
    if (product.isPublishedToHub) {
      return const _Section(
        title: 'Organisation Hub',
        child: Text(
          'This report is published to the Organisation Support Hub.',
        ),
      );
    }

    return _Section(
      title: 'Organisation Hub',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            canPublish
                ? 'You can publish this report for organisation users to discover.'
                : 'This report needs more evidence before it can be published.',
            style: const TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canPublish && !isPublishing ? onPublish : null,
            icon: isPublishing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.public_outlined),
            label: Text(isPublishing ? 'Publishing...' : 'Publish to Hub'),
          ),
        ],
      ),
    );
  }
}

class _AiAssessmentSection extends StatelessWidget {
  const _AiAssessmentSection({
    required this.product,
    required this.isOwner,
    required this.isAssessing,
    required this.onRunAssessment,
  });

  final CompletedProduct product;
  final bool isOwner;
  final bool isAssessing;
  final VoidCallback onRunAssessment;

  @override
  Widget build(BuildContext context) {
    final hasAiAssessment = product.assessmentMethod == 'ai_assisted';

    return _Section(
      title: 'AI Credibility Assessment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAiAssessment) ...[
            _FactRow(
              label: 'Material match',
              value: _scoreText(product.materialMatchScore),
            ),
            _FactRow(
              label: 'DIY output',
              value: _scoreText(product.diyOutputMatchScore),
            ),
            _FactRow(
              label: 'Transformation',
              value: _scoreText(product.transformationPlausibilityScore),
            ),
            _FactRow(
              label: 'Image quality',
              value: _scoreText(product.imageQualityScore),
            ),
            const SizedBox(height: 8),
            Text(product.aiExplanation),
          ] else ...[
            const Text(
              'This report currently uses rule-based evidence completeness only. AI can assess material match, DIY output match, transformation plausibility, and image quality.',
              style: TextStyle(color: EcoLoopTheme.mutedText),
            ),
            if (isOwner && !product.isPublishedToHub) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isAssessing ? null : onRunAssessment,
                icon: isAssessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  isAssessing ? 'Running Assessment...' : 'Run AI Assessment',
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          const Text(
            'This is a plausibility and evidence-quality check, not a guarantee of authenticity.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.product});

  final CompletedProduct product;

  @override
  Widget build(BuildContext context) {
    final hasEmail = product.visibleCreatorEmail.trim().isNotEmpty;
    final hasPhone = product.visibleCreatorPhone.trim().isNotEmpty;

    return _Section(
      title: 'Creator Contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FactRow(
            label: 'Creator',
            value: product.visibleCreatorName.isEmpty
                ? 'Creator name hidden'
                : product.visibleCreatorName,
          ),
          if (hasEmail) _FactRow(label: 'Email', value: product.visibleCreatorEmail),
          if (hasPhone) _FactRow(label: 'Phone', value: product.visibleCreatorPhone),
          if (!hasEmail && !hasPhone)
            const Text(
              'Direct contact details are hidden for this published product.',
              style: TextStyle(color: EcoLoopTheme.mutedText),
            ),
        ],
      ),
    );
  }
}

String _scoreText(int? score) {
  if (score == null) return 'Not assessed';
  return '$score/100';
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: EcoLoopTheme.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: EcoLoopTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

String _availabilityLabel(String value) {
  return switch (value) {
    AvailabilityTypes.donation => 'Donation',
    AvailabilityTypes.sale => 'Sale',
    AvailabilityTypes.collaboration => 'Collaboration',
    AvailabilityTypes.csrOrEventUse => 'CSR / event use',
    _ => 'Showcase only',
  };
}
