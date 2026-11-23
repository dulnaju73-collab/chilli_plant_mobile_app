import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:chilli_plant_health/core/config/api_config.dart';
import 'package:chilli_plant_health/core/network/api_client.dart';
import 'package:chilli_plant_health/features/scanning/presentation/plant_scan_page.dart';
import 'package:chilli_plant_health/models/prediction.dart';
import 'package:chilli_plant_health/models/scan_result.dart';
import 'package:chilli_plant_health/services/prediction_service.dart';

class _StubHttpClient extends http.BaseClient {
  _StubHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

http.StreamedResponse _jsonResponse(
  int statusCode,
  Map<String, dynamic> body,
) {
  final bytes = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(
    Stream<List<int>>.value(bytes),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

ApiClient _buildTestClient(
  Future<http.StreamedResponse> Function(http.BaseRequest request) handler,
) {
  return ApiClient(
    client: _StubHttpClient(handler),
    headersOverride: () async => const {
      'Authorization': 'Bearer test-token',
      'Accept': 'application/json',
    },
  );
}

void main() {
  final sampleImage = File('assets/branding/app_icon.png');

  test('default API_BASE_URL points to https://16.179.128.119', () {
    expect(ApiConfig.baseUrl, 'https://16.179.128.119');
  });

  test('validate parses valid/invalid payloads with optional confidence', () async {
    final validService = PredictionService(
      client: _buildTestClient(
        (request) async {
          expect(request.url.path, '/api/v1/predictions/validate');
          return _jsonResponse(200, {
            'valid': true,
            'message': 'Chilli plant detected.',
            'confidence': 0.94,
          });
        },
      ),
    );

    final validResult = await validService.validate(sampleImage);
    expect(validResult, isA<ValidationResult>());
    expect(validResult.valid, isTrue);
    expect(validResult.message, 'Chilli plant detected.');
    expect(validResult.confidence, 0.94);

    final invalidService = PredictionService(
      client: _buildTestClient(
        (_) async => _jsonResponse(200, {
          'valid': false,
          'message': 'No chilli plant detected.',
          'confidence': null,
        }),
      ),
    );

    final invalidResult = await invalidService.validate(sampleImage);
    expect(invalidResult.valid, isFalse);
    expect(invalidResult.message, 'No chilli plant detected.');
    expect(invalidResult.confidence, isNull);
  });

  test('analyze parses HTTP 422 nested INVALID_PLANT_IMAGE detail', () async {
    const expectedMessage =
        'The uploaded image does not appear to contain a chilli plant. Please upload a clear chilli leaf image.';
    final service = PredictionService(
      client: _buildTestClient(
        (request) async {
          expect(request.url.path, '/api/v1/predictions/analyze');
          return _jsonResponse(422, {
            'detail': {
              'code': 'INVALID_PLANT_IMAGE',
              'message': expectedMessage,
            },
          });
        },
      ),
    );

    await expectLater(
      service.analyze(sampleImage),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.code, 'code', 'INVALID_PLANT_IMAGE')
            .having((e) => e.isInvalidPlantImage, 'isInvalidPlantImage', isTrue)
            .having((e) => e.isNetworkError, 'isNetworkError', isFalse)
            .having((e) => e.message, 'message', expectedMessage),
      ),
    );
  });

  test('error parser handles string detail for HTTP 401/415/422/429/500/503', () async {
    for (final entry in const <int, String>{
      401: 'Authentication required.',
      415: 'Unsupported media type.',
      422: 'The uploaded image file is corrupted.',
      429: 'Rate limit exceeded.',
      500: 'Internal server error.',
      503: 'Model service temporarily unavailable.',
    }.entries) {
      final service = PredictionService(
        client: _buildTestClient(
          (_) async => _jsonResponse(entry.key, {'detail': entry.value}),
        ),
      );

      await expectLater(
        service.analyze(sampleImage),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', entry.key)
              .having((e) => e.code, 'code', isNull)
              .having((e) => e.isNetworkError, 'isNetworkError', isFalse)
              .having((e) => e.message, 'message', entry.value),
        ),
      );
    }
  });

  test('network and timeout exceptions set isNetworkError to true', () async {
    final socketService = PredictionService(
      client: _buildTestClient(
        (_) async => throw const SocketException('Network unreachable'),
      ),
    );
    await expectLater(
      socketService.analyze(sampleImage),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', isTrue),
      ),
    );

    final timeoutService = PredictionService(
      client: _buildTestClient(
        (_) async => throw TimeoutException('Timed out'),
      ),
    );
    await expectLater(
      timeoutService.analyze(sampleImage),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', isTrue),
      ),
    );
  });

  test('Prediction and ScanResult safely handle null image_url and image_path', () async {
    final service = PredictionService(
      client: _buildTestClient(
        (_) async => _jsonResponse(200, {
          'success': true,
          'prediction': {
            'id': 'pred-1',
            'disease': 'Healthy_Leaf',
            'confidence': 97.2,
            'is_healthy': true,
            'created_at': '2026-11-24T01:00:00Z',
            'image_url': null,
            'image_path': null,
          },
        }),
      ),
    );

    final prediction = await service.analyze(sampleImage);
    expect(prediction, isA<Prediction>());
    expect(prediction.disease, 'Healthy_Leaf');
    expect(prediction.confidence, 97.2);
    expect(prediction.isHealthy, isTrue);
    expect(prediction.imageUrl, isNull);
    expect(prediction.imagePath, isNull);

    final scanResult = ScanResult.fromJson({
      'id': 'res-1',
      'disease': 'Curl_Virus',
      'confidence': 88.5,
      'is_healthy': false,
      'validation_status': 'validated',
      'prediction_model_version': 'v1',
      'created_at': '2026-11-24T01:00:00Z',
      'image_url': null,
      'image_path': null,
    });
    expect(scanResult.imageUrl, isNull);
    expect(scanResult.imagePath, isNull);
  });

  testWidgets(
    'PlantScanPage shows clear validation message on HTTP 422 INVALID_PLANT_IMAGE',
    (WidgetTester tester) async {
      const validationMessage =
          'The uploaded image does not appear to contain a chilli plant. Please upload a clear chilli leaf image.';
      final service = PredictionService(
        client: _buildTestClient(
          (_) async => _jsonResponse(422, {
            'detail': {
              'code': 'INVALID_PLANT_IMAGE',
              'message': validationMessage,
            },
          }),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlantScanPage(
            predictionService: service,
            pickImageOverride: (_) async => XFile(sampleImage.path),
          ),
        ),
      );

      final pickButton = find.text('Pick From Gallery');
      await tester.ensureVisible(pickButton);
      await tester.pump();
      await tester.tap(pickButton);
      await tester.pumpAndSettle();

      expect(find.text('Not a Chilli Plant Image'), findsOneWidget);
      expect(find.text(validationMessage), findsOneWidget);
      expect(find.text('Possible Disease Detected'), findsNothing);
      expect(find.textContaining('check the backend connection'), findsNothing);
    },
  );
}
