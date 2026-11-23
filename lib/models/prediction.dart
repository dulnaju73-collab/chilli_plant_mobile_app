import '../core/network/api_client.dart';

class ValidationResult {
  const ValidationResult({
    required this.valid,
    required this.message,
    this.confidence,
  });

  final bool valid;
  final String message;
  final double? confidence;

  factory ValidationResult.fromResponse(Map<String, dynamic> response) {
    final rawConfidence = response['confidence'];
    return ValidationResult(
      valid: response['valid'] == true,
      message: response['message']?.toString().trim() ?? '',
      confidence: rawConfidence is num ? rawConfidence.toDouble() : null,
    );
  }
}

class Prediction {
  const Prediction({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.isHealthy,
    required this.createdAt,
    this.imageUrl,
    this.imagePath,
  });

  final String id;
  final String disease;
  final double confidence;
  final bool isHealthy;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? imagePath;

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory Prediction.fromResponse(Map<String, dynamic> response) {
    if (response['valid'] == false) {
      final message = _nullableString(response['message']) ??
          'The uploaded image does not appear to contain a chilli plant. Please upload a clear chilli leaf image.';
      throw ApiException(
        message,
        statusCode: 422,
        code: ApiException.invalidPlantImageCode,
      );
    }

    final data = response['prediction'];
    if (response['success'] == false || data is! Map<String, dynamic>) {
      final message = _nullableString(response['message']) ??
          'The server returned no prediction.';
      throw ApiException(message);
    }

    return Prediction(
      id: data['id']?.toString() ?? '',
      disease: data['disease']?.toString() ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      isHealthy: data['is_healthy'] == true,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '')?.toLocal(),
      imageUrl: _nullableString(data['image_url']),
      imagePath: _nullableString(data['image_path']),
    );
  }
}
