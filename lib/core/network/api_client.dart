import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => code == null ? message : '$code: $message';
}

class ApiClient {
  ApiClient({FirebaseAuth? auth, http.Client? client})
      : _authOverride = auth,
        _client = client ?? http.Client();

  final FirebaseAuth? _authOverride;
  final http.Client _client;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/api/v1$path')
          .replace(queryParameters: query);

  Future<Map<String, String>> _headers() async {
    User? user;
    try {
      user = _auth.currentUser;
    } catch (_) {
      throw const ApiException(
          'Firebase Authentication is not initialized. Restart the app after checking its Firebase setup.');
    }
    if (user == null) throw const ApiException('Please sign in to continue.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
          'Could not obtain a secure sign-in token. Please sign in again.');
    }
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? query}) async {
    try {
      final response = await _client
          .get(_uri(path, query), headers: await _headers())
          .timeout(ApiConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const ApiException(
          'Could not connect to the server. Check your connection and API_BASE_URL.');
    } on http.ClientException {
      throw const ApiException(
          'Could not connect to the server. Check your connection and API_BASE_URL.');
    }
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .put(_uri(path),
              headers: {
                ...await _headers(),
                'Content-Type': 'application/json'
              },
              body: jsonEncode(body))
          .timeout(ApiConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const ApiException(
          'Could not connect to the server. Check your connection and API_BASE_URL.');
    } on http.ClientException {
      throw const ApiException(
          'Could not connect to the server. Check your connection and API_BASE_URL.');
    }
  }

  Future<Map<String, dynamic>> upload(String path, File file) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headers());
    final name = file.uri.pathSegments.last;
    final extension = name.split('.').last.toLowerCase();
    final subtype = switch (extension) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpeg',
    };
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      await file.readAsBytes(),
      filename: name,
      contentType: http.MediaType('image', subtype),
    ));
    try {
      final streamed =
          await _client.send(request).timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(ApiConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const ApiException(
          'Could not connect to the server. Check your connection and API_BASE_URL.');
    }
  }

  Future<void> delete(String path) async {
    try {
      final response = await _client
          .delete(_uri(path), headers: await _headers())
          .timeout(ApiConfig.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _decode(response);
      }
    } on SocketException {
      throw const ApiException(
          'Could not connect to the server. Check your connection and API_BASE_URL.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map ? body['detail'] : null;
      final message = detail is Map ? detail['message'] : detail;
      final code = detail is Map ? detail['code']?.toString() : null;
      throw ApiException(
        message?.toString() ?? 'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
        code: code,
      );
    }
    if (body is! Map<String, dynamic>) {
      throw const ApiException('The server returned an invalid response.');
    }
    return body;
  }
}
