import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/completed_product.dart';
import '../../models/project_session.dart';
import '../../repositories/completed_guide_repository.dart';
import '../../repositories/completed_product_repository.dart';
import '../../repositories/diy_repository.dart';
import '../../repositories/project_image_repository.dart';
import '../../repositories/project_session_repository.dart';
import '../../services/upcycled_product_report_service.dart';

final _decimalInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  final text = newValue.text;
  if (text.isEmpty || RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
    return newValue;
  }
  return oldValue;
});

class CompletedProductSubmissionScreen extends StatefulWidget {
  const CompletedProductSubmissionScreen({super.key, required this.session});

  final ProjectSession session;

  @override
  State<CompletedProductSubmissionScreen> createState() =>
      _CompletedProductSubmissionScreenState();
}

class _CompletedProductSubmissionScreenState
    extends State<CompletedProductSubmissionScreen> {
  final _productNameController = TextEditingController();
  final List<_MaterialInput> _materialInputs = [
    _MaterialInput(controller: TextEditingController(), quantity: 1),
  ];
  final _timeValueController = TextEditingController();
  final _costController = TextEditingController();
  final _purposeController = TextEditingController();
  final _safetyController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _availableQuantityController = TextEditingController(text: '1');
  final _expectedPriceController = TextEditingController();
  final _locationController = TextEditingController();

  XFile? _beforePhoto;
  XFile? _afterPhoto;
  String _timeUnit = 'hours';
  String _condition = 'Good';
  String _availabilityType = AvailabilityTypes.showcaseOnly;
  bool _canProduceMore = false;
  bool _isAvailableForContact = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _productNameController.text = widget.session.guideTitle;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    for (final input in _materialInputs) {
      input.controller.dispose();
    }
    _timeValueController.dispose();
    _costController.dispose();
    _purposeController.dispose();
    _safetyController.dispose();
    _dimensionsController.dispose();
    _availableQuantityController.dispose();
    _expectedPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required bool isBeforePhoto,
    required ImageSource source,
  }) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1400,
      );
      if (image == null || !mounted) return;
      setState(() {
        if (isBeforePhoto) {
          _beforePhoto = image;
        } else {
          _afterPhoto = image;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select image. Try again.')),
      );
    }
  }

  Future<void> _showImageSourceSheet({required bool isBeforePhoto}) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  isBeforePhoto ? 'Before Photo' : 'After Photo',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Take a photo or select one from gallery.'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(
                    isBeforePhoto: isBeforePhoto,
                    source: ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Select From Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(
                    isBeforePhoto: isBeforePhoto,
                    source: ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMaterialInput() {
    setState(() {
      _materialInputs.add(
        _MaterialInput(controller: TextEditingController(), quantity: 1),
      );
    });
  }

  void _removeMaterialInput(int index) {
    if (_materialInputs.length == 1) return;
    final removed = _materialInputs.removeAt(index);
    removed.controller.dispose();
    setState(() {});
  }

  void _updateMaterialQuantity(int index, int delta) {
    final input = _materialInputs[index];
    final nextQuantity = (input.quantity + delta).clamp(1, 999).toInt();
    setState(() => input.quantity = nextQuantity);
  }

  List<ReusedMaterial> _reusedMaterials() {
    return _materialInputs
        .map(
          (input) => ReusedMaterial(
            material: input.controller.text.trim(),
            quantity: input.quantity,
          ),
        )
        .where((input) => input.material.isNotEmpty)
        .toList();
  }

  String _materialsSummary(List<ReusedMaterial> materials) {
    return materials
        .map((material) => '${material.quantity} x ${material.material}')
        .join(', ');
  }

  String _totalQuantity(List<ReusedMaterial> materials) {
    final total = materials.fold<int>(
      0,
      (sum, material) => sum + material.quantity,
    );
    return total.toString();
  }

  String _moneyValue(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return '';
    return 'RM $value';
  }

  Future<void> _submit() async {
    final validationMessage = _validateForm();
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final imageRepository = ProjectImageRepository();
      final session = widget.session;
      final reusedMaterials = _reusedMaterials();
      final materialsSummary = _materialsSummary(reusedMaterials);
      var beforeImageUrl = session.beforeImageUrl;
      final estimatedCost = _moneyValue(_costController);
      final timeTaken = '${_timeValueController.text.trim()} $_timeUnit';
      final guide = await DiyRepository().fetchGuideById(session.guideId);

      if (_beforePhoto != null) {
        beforeImageUrl = await imageRepository.uploadBeforePhoto(
          userId: session.userId,
          sessionId: session.id,
          image: _beforePhoto!,
        );
      }

      final afterImageUrl = await imageRepository.uploadAfterPhoto(
        userId: session.userId,
        sessionId: session.id,
        image: _afterPhoto!,
      );

      final report = const UpcycledProductReportService()
          .generateRuleBasedDraft(
            productName: _productNameController.text.trim(),
            beforeImageUrl: beforeImageUrl,
            afterImageUrl: afterImageUrl,
            reusedMaterials: reusedMaterials,
            productPurpose: _purposeController.text.trim(),
            estimatedCost: estimatedCost,
            timeTaken: timeTaken,
            safetyNote: _safetyController.text.trim(),
            condition: _condition,
            dimensions: _dimensionsController.text.trim(),
            availabilityType: _availabilityType,
            guide: guide,
          );

      final submissionId = await CompletedProductRepository().createProduct(
        CompletedProduct(
          id: '',
          userId: session.userId,
          guideId: session.guideId,
          projectSessionId: session.id,
          productName: _productNameController.text.trim(),
          materialsUsed: materialsSummary,
          quantityUsed: _totalQuantity(reusedMaterials),
          reusedMaterials: reusedMaterials,
          timeTaken: timeTaken,
          estimatedCost: estimatedCost,
          productPurpose: _purposeController.text.trim(),
          condition: _condition,
          safetyNote: _safetyController.text.trim(),
          dimensions: _dimensionsController.text.trim(),
          availableQuantity: _availableQuantityController.text.trim(),
          canProduceMore: _canProduceMore,
          availabilityType: _availabilityType,
          expectedPriceOrRange: _moneyValue(_expectedPriceController),
          isAvailableForContact: _isAvailableForContact,
          beforeImageUrl: beforeImageUrl,
          afterImageUrl: afterImageUrl,
          location: _locationController.text.trim(),
          verificationStatus: report.verificationStatus,
          evidenceCompletenessScore: report.evidenceCompletenessScore,
          finalVerificationScore: report.finalVerificationScore,
          verificationBadge: report.verificationBadge,
          reportSummary: report.reportSummary,
          evidenceSummary: report.evidenceSummary,
          improvementTips: report.improvementTips,
        ),
      );

      await ProjectSessionRepository().markReportGenerated(
        sessionId: session.id,
        submissionId: submissionId,
        status: report.verificationStatus,
        beforeImageUrl: _beforePhoto == null ? null : beforeImageUrl,
      );
      await CompletedGuideRepository().markCompletedFromSession(
        userId: session.userId,
        session: session,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report generated. Score: ${report.finalVerificationScore}/100.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FirebaseException
                ? 'Unable to submit product: ${error.code}'
                : 'Unable to submit product. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateForm() {
    if (_afterPhoto == null) return 'Please upload an after photo.';
    if (_productNameController.text.trim().isEmpty) {
      return 'Enter product name.';
    }
    final reusedMaterials = _reusedMaterials();
    if (reusedMaterials.isEmpty) {
      return 'Enter at least one reused material.';
    }
    final timeValue = double.tryParse(_timeValueController.text.trim());
    if (timeValue == null || timeValue <= 0) {
      return 'Enter a valid time taken.';
    }
    final costValue = double.tryParse(_costController.text.trim());
    if (costValue == null || costValue < 0) {
      return 'Enter a valid estimated production cost.';
    }
    final availableQuantity = int.tryParse(
      _availableQuantityController.text.trim(),
    );
    if (availableQuantity == null || availableQuantity < 1) {
      return 'Enter a valid available quantity.';
    }
    if (_availabilityType == AvailabilityTypes.sale &&
        _expectedPriceController.text.trim().isEmpty) {
      return 'Enter expected price for sale items.';
    }
    if (_expectedPriceController.text.trim().isNotEmpty) {
      final expectedPrice = double.tryParse(_expectedPriceController.text.trim());
      if (expectedPrice == null || expectedPrice < 0) {
        return 'Enter a valid expected price.';
      }
    }
    if (_purposeController.text.trim().isEmpty) {
      return 'Enter product purpose.';
    }
    if (_safetyController.text.trim().isEmpty) return 'Enter safety note.';
    if (_dimensionsController.text.trim().isEmpty) {
      return 'Enter size or dimensions.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Project')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            session.guideTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Submit product details for future AI-assisted verification and report generation.',
            style: TextStyle(color: EcoLoopTheme.mutedText),
          ),
          const SizedBox(height: 16),
          _PhotoPickerCard(
            title: 'Before Photo',
            subtitle: session.hasBeforePhoto
                ? 'Before photo already saved. You may replace it here.'
                : 'Optional, but improves evidence completeness.',
            existingImageUrl: session.beforeImageUrl,
            selectedImage: _beforePhoto,
            onTap: _isSubmitting
                ? null
                : () => _showImageSourceSheet(isBeforePhoto: true),
          ),
          const SizedBox(height: 12),
          _PhotoPickerCard(
            title: 'After Photo',
            subtitle: 'Required. Show the completed upcycled product clearly.',
            selectedImage: _afterPhoto,
            onTap: _isSubmitting
                ? null
                : () => _showImageSourceSheet(isBeforePhoto: false),
          ),
          const SizedBox(height: 16),
          _TextInput(
            controller: _productNameController,
            label: 'Product name',
          ),
          const SizedBox(height: 4),
          const Text(
            'Materials and quantity reused',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ..._materialInputs.indexed.map(
            (entry) => _MaterialInputRow(
              controller: entry.$2.controller,
              quantity: entry.$2.quantity,
              canRemove: _materialInputs.length > 1,
              onDecrease: () => _updateMaterialQuantity(entry.$1, -1),
              onIncrease: () => _updateMaterialQuantity(entry.$1, 1),
              onRemove: () => _removeMaterialInput(entry.$1),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isSubmitting ? null : _addMaterialInput,
              icon: const Icon(Icons.add),
              label: const Text('Add Material'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TextInput(
                  controller: _timeValueController,
                  label: 'Time taken',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_decimalInputFormatter],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<String>(
                  initialValue: _timeUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const ['minutes', 'hours', 'days']
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _timeUnit = value);
                        },
                ),
              ),
            ],
          ),
          _TextInput(
            controller: _costController,
            label: 'Estimated production cost',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalInputFormatter],
            prefixText: 'RM ',
          ),
          _TextInput(
            controller: _purposeController,
            label: 'Product purpose',
          ),
          DropdownButtonFormField<String>(
            initialValue: _condition,
            decoration: const InputDecoration(
              labelText: 'Condition',
              prefixIcon: Icon(Icons.inventory_outlined),
            ),
            items: const [
              'New',
              'Good',
              'Fair',
              'Needs repair',
              'Decorative only',
            ]
                .map(
                  (condition) => DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value != null) setState(() => _condition = value);
                  },
          ),
          const SizedBox(height: 12),
          _TextInput(controller: _safetyController, label: 'Safety note'),
          _TextInput(
            controller: _dimensionsController,
            label: 'Size or dimensions',
          ),
          _TextInput(
            controller: _availableQuantityController,
            label: 'Available quantity',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _availabilityType,
            decoration: const InputDecoration(
              labelText: 'Availability type',
              prefixIcon: Icon(Icons.handshake_outlined),
            ),
            items: AvailabilityTypes.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(_availabilityLabel(type)),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _availabilityType = value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          _TextInput(
            controller: _expectedPriceController,
            label: 'Expected price or range (optional)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalInputFormatter],
            prefixText: 'RM ',
          ),
          _TextInput(
            controller: _locationController,
            label: 'Creator location (optional)',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _canProduceMore,
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _canProduceMore = value),
            title: const Text('More units can be produced'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isAvailableForContact,
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _isAvailableForContact = value),
            title: const Text('Allow organisation contact later'),
            subtitle: const Text(
              'Contact details only appear if you later publish to the Organisation Support Hub.',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _isSubmitting ? 'Submitting...' : 'Submit For Report',
            icon: Icons.fact_check_outlined,
            onPressed: _isSubmitting ? () {} : _submit,
          ),
        ],
      ),
    );
  }
}

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.existingImageUrl = '',
    this.selectedImage,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String existingImageUrl;
  final XFile? selectedImage;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: _PhotoPreview(
                existingImageUrl: existingImageUrl,
                selectedImage: selectedImage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: EcoLoopTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_a_photo_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.existingImageUrl, this.selectedImage});

  final String existingImageUrl;
  final XFile? selectedImage;

  @override
  Widget build(BuildContext context) {
    final selected = selectedImage;
    if (selected != null) {
      return Image.file(File(selected.path), fit: BoxFit.cover);
    }
    if (existingImageUrl.isNotEmpty) {
      return Image.network(
        existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
      );
    }
    return const _PhotoPlaceholder();
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EcoLoopTheme.softGreen,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: EcoLoopTheme.primary,
        size: 44,
      ),
    );
  }
}

class _MaterialInputRow extends StatelessWidget {
  const _MaterialInputRow({
    required this.controller,
    required this.quantity,
    required this.canRemove,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final TextEditingController controller;
  final int quantity;
  final bool canRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Material',
                hintText: 'e.g. Plastic bottle',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: EcoLoopTheme.softGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Decrease quantity',
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Increase quantity',
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Remove material',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
        ),
      ),
    );
  }
}

class _MaterialInput {
  _MaterialInput({required this.controller, required this.quantity});

  final TextEditingController controller;
  int quantity;
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
