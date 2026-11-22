class Prediction {
  const Prediction(
      {required this.id,
      required this.disease,
      required this.confidence,
      required this.isHealthy,
      required this.createdAt,
      this.imageUrl,
      this.imagePath});

  final String id;
  final String disease;
  final double confidence;
  final bool isHealthy;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? imagePath;

  factory Prediction.fromResponse(Map<String, dynamic> response) {
    final data = response['prediction'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('The server returned no prediction.');
    }
    return Prediction(
      id: data['id']?.toString() ?? '',
      disease: data['disease']?.toString() ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      isHealthy: data['is_healthy'] == true,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '')?.toLocal(),
      imageUrl: data['image_url']?.toString(),
      imagePath: data['image_path']?.toString(),
    );
  }
}
