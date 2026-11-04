import 'dart:async';

import 'package:flutter/services.dart';

import 'exceptions.dart';

class NativePush {
  NativePush() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onToken' && call.arguments is String) {
        _refreshes.add(call.arguments as String);
      }
    });
  }

  static const MethodChannel _channel = MethodChannel('flare_push');

  final StreamController<String> _refreshes = StreamController<String>.broadcast();

  Stream<String> get tokenRefreshes => _refreshes.stream;

  Future<String> getToken([Map<String, String>? firebaseOptions]) async {
    try {
      final token = await _channel
          .invokeMethod<String>('getToken', firebaseOptions)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw FlareException('The phone took too long to give a push token');
      });
      if (token == null || token.isEmpty) {
        throw FlareException('The phone did not give a push token');
      }
      return token;
    } on PlatformException catch (error) {
      throw FlareException(
          'Could not get the push token: ${error.message ?? error.code}');
    }
  }

  void close() {
    _channel.setMethodCallHandler(null);
    _refreshes.close();
  }
}
