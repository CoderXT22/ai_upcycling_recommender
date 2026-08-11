import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ai_detection_result.dart';

class AiDetectionService {
  const AiDetectionService();

  Future<AiDetectionResult> detectWasteFromImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final callable = FirebaseFunctions.instance.httpsCallable('detectWaste');
    final response = await callable.call<Map<String, dynamic>>({
      'imageBase64': base64Encode(bytes),
      'mimeType': _mimeTypeForPath(image.path),
    });

    final data = response.data;
    return AiDetectionResult(
      object: _stringValue(data['object'], fallback: 'Unknown item'),
      material: _stringValue(data['material'], fallback: 'Unknown material'),
      category: _appCategoryValue(data['category']),
      confidence: _confidenceValue(data['confidence']),
      note: _stringValue(data['reason']),
    );
  }

  Future<AiDetectionResult> detectWasteFromImagePlaceholder() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const AiDetectionResult(
      object: 'Plastic bottle',
      material: 'PET plastic',
      category: 'plastic',
      confidence: 0.82,
      note: 'Simulated AI result. Replace this service with Gemini later.',
    );
  }

  String _mimeTypeForPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _appCategoryValue(Object? value) {
    final category = _stringValue(value).toLowerCase().trim();
    return switch (category) {
      'electronic_waste' => 'electronic waste',
      'non_recyclable' => 'non-recyclable waste',
      _ => category,
    };
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  double _confidenceValue(Object? value) {
    if (value is num) return value.clamp(0, 1).toDouble();
    return 0.5;
  }
}
