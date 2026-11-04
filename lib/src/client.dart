import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';

class FlareClient {
  FlareClient({
    required String baseUrl,
    required this.appId,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _http = httpClient ?? http.Client();

  final String appId;
  final Duration timeout;
  final String _baseUrl;
  final http.Client _http;

  Future<String> registerDevice({
    required String token,
    required String platform,
    String provider = 'fcm',
    String? userId,
    String? identityToken,
  }) async {
    final body = await _send('POST', '/v1/devices', {
      'token': token,
      'platform': platform,
      'provider': provider,
      if (userId != null) 'externalUserId': userId,
      if (userId != null && identityToken != null) 'identityToken': identityToken,
    });
    final id = body?['id'];
    if (id is! String) {
      throw FlareException('Flare answered without a device id');
    }
    return id;
  }

  Future<void> setUser(String deviceId, String userId,
      {String? identityToken}) async {
    await _send('PUT', '/v1/devices/$deviceId/user', {
      'userId': userId,
      if (identityToken != null) 'identityToken': identityToken,
    });
  }

  Future<void> clearUser(String deviceId) async {
    await _send('DELETE', '/v1/devices/$deviceId/user');
  }

  Future<void> subscribe(String deviceId, String topic) async {
    await _send(
        'POST', '/v1/devices/$deviceId/topics/${Uri.encodeComponent(topic)}');
  }

  Future<void> unsubscribe(String deviceId, String topic) async {
    await _send(
        'DELETE', '/v1/devices/$deviceId/topics/${Uri.encodeComponent(topic)}');
  }

  Future<Map<String, String>> firebaseOptions(String platform) async {
    final body = await _send('GET', '/v1/config?platform=$platform');
    if (body == null) {
      throw FlareException('Flare answered without Firebase settings');
    }
    return {
      for (final key in ['apiKey', 'appId', 'messagingSenderId', 'projectId'])
        key: body[key] as String,
    };
  }

  void close() => _http.close();

  Future<Map<String, dynamic>?> _send(String method, String path,
      [Map<String, Object?>? body]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['x-app-id'] = appId;
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
          await _http.send(request).timeout(timeout));
    } on TimeoutException {
      throw FlareException('Flare did not answer in time');
    } on http.ClientException catch (error) {
      throw FlareException('Could not reach Flare: ${error.message}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw FlareException(_errorMessage(response),
        statusCode: response.statusCode);
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      return 'Flare answered with status ${response.statusCode}';
    }
    return 'Flare answered with status ${response.statusCode}';
  }
}
