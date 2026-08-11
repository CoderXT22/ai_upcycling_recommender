import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/completed_product.dart';
import '../../repositories/completed_product_repository.dart';
import '../projects/upcycled_product_report_screen.dart';

class OrganisationSupportHubScreen extends StatefulWidget {
  const OrganisationSupportHubScreen({super.key});

  @override
  State<OrganisationSupportHubScreen> createState() =>
      _OrganisationSupportHubScreenState();
}

class _OrganisationSupportHubScreenState
    extends State<OrganisationSupportHubScreen> {
  String _availabilityFilter = 'all';
  String _assessmentFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Hub')),
      body: StreamBuilder<List<CompletedProduct>>(
        stream: CompletedProductRepository().watchPublishedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HubMessage(
              title: 'Unable to load products',
              message: snapshot.error is FirebaseException
                  ? 'Firebase error: ${(snapshot.error as FirebaseException).code}.'
                  : 'Please check your connection and try again.',
            );
          }

          final products = snapshot.data ?? const <CompletedProduct>[];
          final filtered = products.where((product) {
            final matchesAvailability = _availabilityFilter == 'all' ||
                product.availabilityType == _availabilityFilter;
            final matchesAssessment = _assessmentFilter == 'all' ||
                product.assessmentMethod == _assessmentFilter;
            return matchesAvailability && matchesAssessment;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Published Upcycled Products',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse creator-published products and impact reports.',
                style: TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 14),
              const Text(
                'Assessment',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      value: 'all',
                      selectedValue: _assessmentFilter,
                      onSelected: _setAssessmentFilter,
                    ),
                    _FilterChip(
                      label: 'AI-Assessed',
                      value: 'ai_assisted',
                      selectedValue: _assessmentFilter,
                      onSelected: _setAssessmentFilter,
                    ),
                    _FilterChip(
                      label: 'Preliminary',
                      value: 'rule_based_evidence_only',
                      selectedValue: _assessmentFilter,
                      onSelected: _setAssessmentFilter,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Availability',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      value: 'all',
                      selectedValue: _availabilityFilter,
                      onSelected: _setAvailabilityFilter,
                    ),
                    ...AvailabilityTypes.values.map(
                      (value) => _FilterChip(
                        label: _availabilityLabel(value),
                        value: value,
                        selectedValue: _availabilityFilter,
                        onSelected: _setAvailabilityFilter,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const _HubMessage(
                  title: 'No published products yet',
                  message: 'User-published reports will appear here.',
                )
              else if (filtered.isEmpty)
                const _HubMessage(
                  title: 'No matching products',
                  message: 'Try another availability filter.',
                )
              else
                ...filtered.map(
                  (product) => _PublishedProductCard(product: product),
                ),
            ],
          );
        },
      ),
    );
  }

  void _setAvailabilityFilter(String value) {
    setState(() => _availabilityFilter = value);
  }

  void _setAssessmentFilter(String value) {
    setState(() => _assessmentFilter = value);
  }
}

class _PublishedProductCard extends StatelessWidget {
  const _PublishedProductCard({required this.product});

  final CompletedProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UpcycledProductReportScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.network(
                product.afterImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: EcoLoopTheme.softGreen,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    color: EcoLoopTheme.primary,
                    size: 42,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HubPill('${product.finalVerificationScore}/100'),
                      _HubPill(product.verificationBadge),
                      _HubPill(_assessmentLabel(product.assessmentMethod)),
                      _HubPill(_availabilityLabel(product.availabilityType)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.productPurpose,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EcoLoopTheme.mutedText),
                  ),
                  if (product.visibleCreatorName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Creator: ${product.visibleCreatorName}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
        selectedColor: EcoLoopTheme.primary,
        backgroundColor: EcoLoopTheme.softGreen,
        labelStyle: TextStyle(
          color: selected ? Colors.white : EcoLoopTheme.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HubPill extends StatelessWidget {
  const _HubPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EcoLoopTheme.softGreen,
        borderRadius: BorderRadius.circular(18),
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

class _HubMessage extends StatelessWidget {
  const _HubMessage({required this.title, required this.message});

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

String _availabilityLabel(String value) {
  return switch (value) {
    AvailabilityTypes.donation => 'Donation',
    AvailabilityTypes.sale => 'Sale',
    AvailabilityTypes.collaboration => 'Collaboration',
    AvailabilityTypes.csrOrEventUse => 'CSR / event use',
    _ => 'Showcase only',
  };
}

String _assessmentLabel(String value) {
  return switch (value) {
    'ai_assisted' => 'AI-Assessed',
    _ => 'Preliminary',
  };
}
