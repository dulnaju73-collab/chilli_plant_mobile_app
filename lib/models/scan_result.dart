class ScanResult {
  const ScanResult({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.isHealthy,
    required this.validationStatus,
    required this.modelVersion,
    this.createdAt,
    this.imageUrl,
    this.imagePath,
  });

  final String id;
  final String disease;
  final double confidence;
  final bool isHealthy;
  final String validationStatus;
  final String modelVersion;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? imagePath;

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id']?.toString() ?? '',
        disease: json['disease']?.toString() ?? 'Unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        isHealthy: json['is_healthy'] == true,
        validationStatus: json['validation_status']?.toString() ?? 'validated',
        modelVersion: json['prediction_model_version']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
        imageUrl: _nullableString(json['image_url']),
        imagePath: _nullableString(json['image_path']),
      );
}

class ResultsPageData {
  const ResultsPageData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<ScanResult> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory ResultsPageData.fromJson(Map<String, dynamic> json) =>
      ResultsPageData(
        items: (json['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ScanResult.fromJson)
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
        hasMore: json['has_more'] == true,
      );
}
