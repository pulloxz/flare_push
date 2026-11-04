import 'dart:async';

import 'package:flutter/foundation.dart';

import 'client.dart';
import 'exceptions.dart';
import 'native.dart';

class Flare {
  Flare._();

  static FlareClient? _client;
  static NativePush? _native;
  static String? _deviceId;
  static String? _userId;
  static String? _identityToken;
  static final Set<String> _topics = {};
  static StreamSubscription<String>? _tokenRefreshes;
  static Future<void>? _registration;

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> init(
      {required String baseUrl, required String appId}) async {
    if (kIsWeb) {
      throw UnsupportedError('Flare supports Android and iOS only');
    }

    await _tokenRefreshes?.cancel();
    _native?.close();
    _client?.close();
    _client = FlareClient(baseUrl: baseUrl, appId: appId);
    _native = NativePush();
    _deviceId = null;
    _registration = null;

    _tokenRefreshes = _native!.tokenRefreshes.listen((token) {
      _registration = _register(token).catchError(_report);
    });

    final token = await _currentToken();
    if (token != null) {
      _registration = _register(token).catchError(_report);
      await _registration;
    }
  }

  static Future<void> login(String userId, {String? identityToken}) async {
    _userId = userId;
    _identityToken = identityToken;
    final deviceId = await _ensureRegistered();
    await _requireClient()
        .setUser(deviceId, userId, identityToken: identityToken);
  }

  static Future<void> logout() async {
    _userId = null;
    _identityToken = null;
    final deviceId = _deviceId;
    if (deviceId == null) return;
    await _requireClient().clearUser(deviceId);
  }

  static Future<void> subscribe(String topic) async {
    final deviceId = await _ensureRegistered();
    await _requireClient().subscribe(deviceId, topic);
    _topics.add(topic);
  }

  static Future<void> unsubscribe(String topic) async {
    final deviceId = await _ensureRegistered();
    await _requireClient().unsubscribe(deviceId, topic);
    _topics.remove(topic);
  }

  static FlareClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Call Flare.init() before using Flare');
    }
    return client;
  }

  static Future<String?> _currentToken() async {
    try {
      final options = _isIos
          ? null
          : await _requireClient().firebaseOptions('android');
      return await _native!.getToken(options);
    } catch (error) {
      debugPrint(
          'Flare: could not get the push token yet ($error). Waiting for the next one.');
      return null;
    }
  }

  static Future<void> _register(String token) async {
    final client = _requireClient();
    final deviceId = await client.registerDevice(
      token: token,
      platform: _isIos ? 'ios' : 'android',
      provider: _isIos ? 'apns' : 'fcm',
      userId: _userId,
      identityToken: _identityToken,
    );
    _deviceId = deviceId;
    for (final topic in _topics) {
      await client.subscribe(deviceId, topic);
    }
  }

  static void _report(Object error) {
    debugPrint('Flare: registering this device failed: $error');
  }

  static Future<String> _ensureRegistered() async {
    _requireClient();
    await _registration;

    final known = _deviceId;
    if (known != null) return known;

    final token = await _currentToken();
    if (token != null) {
      await _register(token);
      final registered = _deviceId;
      if (registered != null) return registered;
    }
    throw FlareException(
      'This device is not registered with Flare yet. Check that the Flare settings for this project are complete and notifications are allowed.',
    );
  }
}
