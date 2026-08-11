import 'package:cloud_functions/cloud_functions.dart';

class AiUpcycledVerificationResult {
  const AiUpcycledVerificationResult({
    required this.finalVerificationScore,
    required this.verificationBadge,
    required this.verificationStatus,
  });

  final int finalVerificationScore;
  final String verificationBadge;
  final String verificationStatus;
}

class AiUpcycledVerificationService {
  const AiUpcycledVerificationService();

  Future<AiUpcycledVerificationResult> verifyProduct(String productId) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'verifyUpcycledProduct',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
    );
    final response = await callable.call<Map<String, dynamic>>({
      'productId': productId,
    });
    final data = response.data;
    return AiUpcycledVerificationResult(
      finalVerificationScore: _intValue(data['finalVerificationScore']),
      verificationBadge: _stringValue(data['verificationBadge']),
      verificationStatus: _stringValue(data['verificationStatus']),
    );
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return '';
  }
}
