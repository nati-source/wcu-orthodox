import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FirebaseCallableException implements Exception {
  final String code;
  final String message;

  const FirebaseCallableException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Small callable-protocol client used to avoid writing trusted records from
/// Firestore clients. Requests are authenticated with the current Firebase ID
/// token and the Functions endpoint remains configurable for emulator runs.
class FirebaseCallableService {
  FirebaseCallableService._();

  static final FirebaseCallableService instance = FirebaseCallableService._();
  static const _projectId = 'wcu-orthodox';
  static const _region = 'us-central1';
  static const _emulatorEnabled = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
  );
  static const _emulatorHost = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_EMULATOR_HOST',
    defaultValue: '',
  );

  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String get _endpointBase {
    if (!_emulatorEnabled) {
      return 'https://$_region-$_projectId.cloudfunctions.net';
    }
    final host = _emulatorHost.isNotEmpty
        ? _emulatorHost
        : (defaultTargetPlatform == TargetPlatform.android
              ? '10.0.2.2'
              : '127.0.0.1');
    return 'http://$host:5001/$_projectId/$_region';
  }

  Future<Map<String, dynamic>> call(
    String functionName, [
    Map<String, dynamic> data = const {},
  ]) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    if (user == null) {
      throw const FirebaseCallableException(
        'unauthenticated',
        'Sign in again before continuing.',
      );
    }
    final token = await user.getIdToken();
    final response = await http
        .post(
          Uri.parse('$_endpointBase/$functionName'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 120));

    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw FirebaseCallableException(
        'internal',
        'The server returned an unreadable response (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'];
      if (error is Map) {
        throw FirebaseCallableException(
          (error['status'] ?? 'unknown').toString(),
          (error['message'] ?? 'The request failed.').toString(),
        );
      }
      throw FirebaseCallableException(
        'internal',
        'The server rejected the request (${response.statusCode}).',
      );
    }
    final result = body['data'] ?? body['result'] ?? const <String, dynamic>{};
    if (result is! Map) {
      throw const FirebaseCallableException(
        'internal',
        'The server response has an invalid data format.',
      );
    }
    return Map<String, dynamic>.from(result);
  }
}
