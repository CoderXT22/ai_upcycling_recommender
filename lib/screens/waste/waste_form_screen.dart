import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/constants/waste_categories.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../mock/mock_data.dart';
import '../diy/diy_guide_detail_screen.dart';

class WasteFormScreen extends StatefulWidget {
  const WasteFormScreen({super.key});

  @override
  State<WasteFormScreen> createState() => _WasteFormScreenState();
}

class _WasteFormScreenState extends State<WasteFormScreen> {
  final _objectController = TextEditingController();
  String? _material;
  String? _category;
  bool _showRecommendation = false;

  @override
  void dispose() {
    _objectController.dispose();
    super.dispose();
  }

  void _simulateAiDetection() {
    setState(() {
      _objectController.text = 'Plastic bottle';
      _material = 'PET plastic';
      _category = 'plastic';
      _showRecommendation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(
          title: 'Waste Recommendation',
          subtitle: 'Add waste items manually or scan with camera',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item 1',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(
                        color: EcoLoopTheme.primary,
                        style: BorderStyle.solid,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _simulateAiDetection,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scan Waste Item'),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('Object Name'),
                  TextField(
                    controller: _objectController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Plastic bottle',
                    ),
                    onChanged: (_) =>
                        setState(() => _showRecommendation = false),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('Material Type'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('material-$_material'),
                    initialValue: _material,
                    hint: const Text('Select Material...'),
                    items:
                        const [
                              'PET plastic',
                              'Glass',
                              'Metal',
                              'Paper',
                              'Fabric',
                              'Electronic parts',
                              'Mixed waste',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _material = value;
                        _showRecommendation = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('Waste Category'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category-$_category'),
                    initialValue: _category,
                    hint: const Text('Select Category...'),
                    items: WasteCategories.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                        _showRecommendation = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add multiple items'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            label: 'Get Recommendation',
            icon: Icons.near_me_outlined,
            onPressed: () => setState(() => _showRecommendation = true),
          ),
        ),
        if (_showRecommendation) const _RecommendationPreview(),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: EcoLoopTheme.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecommendationPreview extends StatelessWidget {
  const _RecommendationPreview();

  @override
  Widget build(BuildContext context) {
    final guide = mockDiyGuides.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended Upcycling',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(guide.title),
              const SizedBox(height: 4),
              Text(
                guide.description,
                style: const TextStyle(color: EcoLoopTheme.mutedText),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiyGuideDetailScreen(guide: guide),
                    ),
                  );
                },
                child: const Text('View DIY Guide'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
