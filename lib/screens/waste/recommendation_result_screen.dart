import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/diy_guide.dart';
import '../../models/recommendation_result.dart';
import '../../models/recycling_centre.dart';
import '../../models/sustainability_event.dart';
import '../../models/waste_item.dart';
import '../../services/recommendation_service.dart';
import '../centres/recycling_centres_screen.dart';
import '../diy/diy_guide_detail_screen.dart';
import '../events/sustainability_events_screen.dart';

class RecommendationResultScreen extends StatelessWidget {
  const RecommendationResultScreen({super.key, required this.wasteItem});

  final WasteItem wasteItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: FutureBuilder<RecommendationResult>(
        future: RecommendationService().recommend(wasteItem),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ResultMessage(
              title: 'Recommendation unavailable',
              message: 'Please check your connection and try again.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          final result = snapshot.data;
          if (result == null) {
            return _ResultMessage(
              title: 'No recommendation generated',
              message: 'Go back and confirm the waste item details again.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WasteSummary(wasteItem: result.wasteItem),
              const SizedBox(height: 18),
              _GuideSection(guides: result.guides),
              const SizedBox(height: 18),
              _CentreSection(
                centres: result.centres,
                category: result.wasteItem.category,
              ),
              const SizedBox(height: 18),
              _GuidanceSection(disposalNote: result.disposalNote),
              const SizedBox(height: 18),
              _WarningSection(warning: result.contaminationWarning),
              const SizedBox(height: 18),
              _EventSection(events: result.events),
            ],
          );
        },
      ),
    );
  }
}

class _WasteSummary extends StatelessWidget {
  const _WasteSummary({required this.wasteItem});

  final WasteItem wasteItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmed Waste Item',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _SummaryRow(label: 'Object', value: wasteItem.object),
            _SummaryRow(label: 'Material', value: wasteItem.material),
            _SummaryRow(label: 'Category', value: wasteItem.category),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(color: EcoLoopTheme.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.guides});

  final List<DiyGuide> guides;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '1. Recommended DIY Guides',
      child: guides.isEmpty
          ? const _MutedText('No matching upcycling guides found yet.')
          : SizedBox(
              height: 184,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: guides.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final guide = guides[index];
                  return SizedBox(
                    width: 230,
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DiyGuideDetailScreen(guide: guide),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.handyman_outlined,
                                color: EcoLoopTheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                guide.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                guide.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EcoLoopTheme.mutedText,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${guide.difficultyLevel} - ${guide.estimatedTime}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _CentreSection extends StatelessWidget {
  const _CentreSection({required this.centres, required this.category});

  final List<RecyclingCentre> centres;
  final String category;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '2. Recycling / Donation Centres',
      actionLabel: 'View all',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecyclingCentresScreen(initialCategory: category),
          ),
        );
      },
      child: centres.isEmpty
          ? const _MutedText('No matching Selangor centres found yet.')
          : Column(
              children: centres.take(3).map((centre) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: EcoLoopTheme.primary,
                  ),
                  title: Text(centre.name),
                  subtitle: Text('${centre.area} - ${centre.status}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecyclingCentresScreen(initialCategory: category),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection({required this.disposalNote});

  final String disposalNote;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '3. Disposal Guidance',
      child: _MutedText(
        disposalNote.isEmpty
            ? 'If reuse, donation, or recycling is not possible, dispose of the item according to local waste rules and avoid mixing it with clean recyclables.'
            : disposalNote,
      ),
    );
  }
}

class _WarningSection extends StatelessWidget {
  const _WarningSection({required this.warning});

  final String warning;

  @override
  Widget build(BuildContext context) {
    if (warning.isEmpty) {
      return const _Section(
        title: '4. Contamination Warning',
        child: _MutedText('No specific contamination warning for this item.'),
      );
    }

    return _Section(
      title: '4. Contamination Warning',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_outlined, color: Color(0xFF9A6200)),
            const SizedBox(width: 10),
            Expanded(child: Text(warning)),
          ],
        ),
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({required this.events});

  final List<SustainabilityEvent> events;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '5. Suitable Events',
      actionLabel: 'View events',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SustainabilityEventsScreen()),
        );
      },
      child: events.isEmpty
          ? const _MutedText('No matching public event shoutouts found yet.')
          : Column(
              children: events.take(3).map((event) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.event_outlined,
                    color: EcoLoopTheme.primary,
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    event.benefit.isEmpty ? event.dateText : event.benefit,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SustainabilityEventsScreen(),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: EcoLoopTheme.mutedText));
  }
}

class _ResultMessage extends StatelessWidget {
  const _ResultMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Back to form')),
          ],
        ),
      ),
    );
  }
}
