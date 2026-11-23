import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.isNetworkError = false,
  });

  static const String invalidPlantImageCode = 'INVALID_PLANT_IMAGE';

  final String message;
  final int? statusCode;
  final String? code;
  final bool isNetworkError;

  bool get isInvalidPlantImage => code == invalidPlantImageCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    FirebaseAuth? auth,
    http.Client? client,
    Future<Map<String, String>> Function()? headersOverride,
  })  : _authOverride = auth,
        _client = client ?? http.Client(),
        _headersOverride = headersOverride;

  final FirebaseAuth? _authOverride;
  final http.Client _client;
  final Future<Map<String, String>> Function()? _headersOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/api/v1$path')
          .replace(queryParameters: query);

  Future<Map<String, String>> _headers() async {
    if (_headersOverride != null) {
      return _headersOverride!();
    }

    User? user;
    try {
      user = _auth.currentUser;
    } catch (_) {
      throw const ApiException(
        'Firebase Authentication is not initialized. Restart the app after checking its Firebase setup.',
      );
    }
    if (user == null) {
      throw const ApiException('Please sign in to continue.', statusCode: 401);
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Could not obtain a secure sign-in token. Please sign in again.',
        statusCode: 401,
      );
    }
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  Future<T> _guardNetwork<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The request timed out. Please check your connection and try again.',
        isNetworkError: true,
      );
    } on HandshakeException {
      throw const ApiException(
        'Could not establish a secure connection to the server. Please try again later.',
        isNetworkError: true,
      );
    } on SocketException {
      throw const ApiException(
        'Could not connect to the server. Check your internet connection and try again.',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not connect to the server. Check your internet connection and try again.',
        isNetworkError: true,
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) =>
      _guardNetwork(() async {
        final response = await _client
            .get(_uri(path, query), headers: await _headers())
            .timeout(ApiConfig.requestTimeout);
        return _decode(response);
      });

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _guardNetwork(() async {
        final response = await _client
            .put(
              _uri(path),
              headers: {
                ...await _headers(),
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(ApiConfig.requestTimeout);
        return _decode(response);
      });

  Future<Map<String, dynamic>> upload(String path, File file) =>
      _guardNetwork(() async {
        final request = http.MultipartRequest('POST', _uri(path));
        request.headers.addAll(await _headers());
        final name = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'leaf.jpg';
        final extension = name.contains('.')
            ? name.split('.').last.toLowerCase()
            : 'jpg';
        final subtype = switch (extension) {
          'png' => 'png',
          'webp' => 'webp',
          _ => 'jpeg',
        };
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: name,
            contentType: http.MediaType('image', subtype),
          ),
        );
        final streamed =
            await _client.send(request).timeout(ApiConfig.requestTimeout);
        final response = await http.Response.fromStream(streamed)
            .timeout(ApiConfig.requestTimeout);
        return _decode(response);
      });

  Future<void> delete(String path) => _guardNetwork(() async {
        final response = await _client
            .delete(_uri(path), headers: await _headers())
            .timeout(ApiConfig.requestTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _decode(response);
        }
      });

  Map<String, dynamic> _decode(http.Response response) {
    final body = _tryDecodeJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw parseErrorResponse(response, decodedBody: body);
    }
    if (body is! Map<String, dynamic>) {
      throw const ApiException('The server returned an invalid response.');
    }
    return body;
  }

  static dynamic _tryDecodeJson(http.Response response) {
    try {
      final raw = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
      if (raw.isEmpty) return null;
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static String? _nonEmptyString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Parses backend HTTP error responses where `detail` may be either:
  /// - a nested map: `{"detail": {"code": "INVALID_PLANT_IMAGE", "message": "..."}}`
  /// - a string: `{"detail": "..."}`
  /// - a FastAPI validation list: `{"detail": [{"msg": "..."}]}`
  static ApiException parseErrorResponse(
    http.Response response, {
    dynamic decodedBody,
  }) {
    final body = decodedBody ?? _tryDecodeJson(response);
    String? message;
    String? code;

    if (body is Map) {
      final detail = body['detail'];
      if (detail is Map) {
        code = _nonEmptyString(detail['code']);
        message = _nonEmptyString(detail['message']) ??
            _nonEmptyString(detail['error']);
      } else if (detail is String) {
        message = _nonEmptyString(detail);
      } else if (detail is List) {
        final parts = detail
            .map((entry) {
              if (entry is Map) {
                return _nonEmptyString(entry['msg']) ??
                    _nonEmptyString(entry['message']);
              }
              return _nonEmptyString(entry);
            })
            .whereType<String>()
            .toList();
        if (parts.isNotEmpty) {
          message = parts.join(' ');
        }
      }

      code ??= _nonEmptyString(body['code']);
      message ??=
          _nonEmptyString(body['message']) ?? _nonEmptyString(body['error']);
    }

    message ??= _defaultMessageForStatus(response.statusCode, code);

    return ApiException(
      message,
      statusCode: response.statusCode,
      code: code,
    );
  }

  static String _defaultMessageForStatus(int statusCode, String? code) {
    if (code == ApiException.invalidPlantImageCode) {
      return 'The uploaded image does not appear to contain a chilli plant. Please upload a clear chilli leaf image.';
    }
    return switch (statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      415 => 'Unsupported image format. Please upload a JPEG, PNG, or WebP image.',
      429 => 'Too many requests. Please wait a moment and try again.',
      _ => 'Request failed ($statusCode).',
    };
  }
}
