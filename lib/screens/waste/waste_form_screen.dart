import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../core/constants/waste_categories.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../models/ai_detection_result.dart';
import '../../models/waste_item.dart';
import '../../services/ai_detection_service.dart';
import 'recommendation_result_screen.dart';

class WasteFormScreen extends StatefulWidget {
  const WasteFormScreen({super.key});

  @override
  State<WasteFormScreen> createState() => _WasteFormScreenState();
}

class _WasteFormScreenState extends State<WasteFormScreen> {
  final _objectController = TextEditingController();
  String? _material;
  String? _category;
  String _source = 'manual';
  AiDetectionResult? _detectedResult;
  XFile? _selectedImage;
  bool _isDetecting = false;

  @override
  void dispose() {
    _objectController.dispose();
    super.dispose();
  }

  Future<void> _scanWasteItem() async {
    final imageSource = await _showImageSourceSheet();
    if (imageSource == null) return;

    setState(() => _isDetecting = true);
    try {
      final image = await ImagePicker().pickImage(
        source: imageSource,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (!mounted) return;
      if (image == null) {
        setState(() => _isDetecting = false);
        return;
      }

      setState(() {
        _selectedImage = image;
        _detectedResult = null;
      });

      final result = await const AiDetectionService().detectWasteFromImage(
        image,
      );
      if (!mounted) return;
      setState(() {
        _detectedResult = result;
        _source = 'manual';
        _isDetecting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDetecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI detection failed. You can try again or fill the form manually.',
          ),
        ),
      );
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Scan Waste Item',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Choose how to provide the waste image.'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Select From Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyDetectedResult(AiDetectionResult result) {
    setState(() {
      _objectController.text = result.object;
      _material = result.material;
      _category = result.category;
      _source = 'ai';
    });
  }

  void _openRecommendations() {
    final object = _objectController.text.trim();
    final material = _material;
    final category = _category;

    if (object.isEmpty || material == null || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in object, material, and category first.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecommendationResultScreen(
          wasteItem: WasteItem(
            object: object,
            material: material,
            category: category,
            source: _source,
            confidence: _source == 'ai' ? _detectedResult?.confidence : null,
          ),
        ),
      ),
    );
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
                    onPressed: _isDetecting ? null : _scanWasteItem,
                    icon: _isDetecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _isDetecting ? 'Detecting...' : 'Scan Waste Item',
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    _SelectedWasteImage(image: _selectedImage!),
                  ],
                  if (_detectedResult != null) ...[
                    const SizedBox(height: 12),
                    _AiDetectionPreview(
                      result: _detectedResult!,
                      isApplied:
                          _source == 'ai' &&
                          _objectController.text.trim() ==
                              _detectedResult!.object &&
                          _material == _detectedResult!.material &&
                          _category == _detectedResult!.category,
                      onApply: () => _applyDetectedResult(_detectedResult!),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const _FieldLabel('Object Name'),
                  TextField(
                    controller: _objectController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Plastic bottle',
                    ),
                    onChanged: (_) => setState(() => _source = 'manual'),
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
                        _source = 'manual';
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
                        _source = 'manual';
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
            onPressed: _openRecommendations,
          ),
        ),
      ],
    );
  }
}

class _AiDetectionPreview extends StatelessWidget {
  const _AiDetectionPreview({
    required this.result,
    required this.isApplied,
    required this.onApply,
  });

  final AiDetectionResult result;
  final bool isApplied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EcoLoopTheme.softGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EcoLoopTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: EcoLoopTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI detected ${result.object}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${result.confidencePercent}%',
                style: const TextStyle(
                  color: EcoLoopTheme.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetectionLine(label: 'Object', value: result.object),
          _DetectionLine(label: 'Material', value: result.material),
          _DetectionLine(label: 'Category', value: result.category),
          const SizedBox(height: 8),
          const Text(
            'Please apply the result, then review or edit the form before getting recommendations.',
            style: TextStyle(color: EcoLoopTheme.mutedText, fontSize: 12),
          ),
          if (result.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.note,
              style: const TextStyle(
                color: EcoLoopTheme.mutedText,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isApplied ? null : onApply,
              icon: Icon(isApplied ? Icons.check : Icons.edit_outlined),
              label: Text(isApplied ? 'Applied' : 'Apply to Form'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedWasteImage extends StatelessWidget {
  const _SelectedWasteImage({required this.image});

  final XFile image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 170,
        width: double.infinity,
        color: EcoLoopTheme.softGreen,
        child: Image.file(
          File(image.path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: EcoLoopTheme.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionLine extends StatelessWidget {
  const _DetectionLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text('$label: $value', style: const TextStyle(fontSize: 13)),
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
