import 'dart:io';

import '../core/network/api_client.dart';
import '../models/prediction.dart';

class PredictionService {
  PredictionService({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<ValidationResult> validate(File image) async =>
      ValidationResult.fromResponse(
        await _client.upload('/predictions/validate', image),
      );

  Future<Prediction> analyze(File image) async => Prediction.fromResponse(
        await _client.upload('/predictions/analyze', image),
      );

  Future<List<String>> classes() async {
    final response = await _client.get('/predictions/classes');
    return (response['classes'] as List? ?? const [])
        .map((value) => value.toString())
        .toList();
  }
}
