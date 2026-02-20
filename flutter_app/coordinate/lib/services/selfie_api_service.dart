import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'clothes_api_service.dart' as app;

class SelfieApiService {
  static const String _apiName = 'apif4831e80';

  Map<String, dynamic> _decodeJsonOrThrow(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw const FormatException('Response is not a JSON object');
    } catch (e) {
      throw FormatException('Invalid JSON response: $e');
    }
  }

  String _truncate(String value, {int max = 2000}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}\n... (truncated)';
  }

  Never _throwHttpError(dynamic response) {
    final status = response.statusCode;
    final body = _truncate(response.decodeBody());
    throw app.ApiException('HTTP $status\n$body');
  }

  void _throwIfNotOk(Map<String, dynamic> decoded) {
    final ok = decoded['ok'];
    if (ok == true) {
      return;
    }
    final error = decoded['error'];
    if (error is String && error.isNotEmpty) {
      throw app.ApiException(error);
    }
    throw const app.ApiException('API error');
  }

  Future<Map<String, dynamic>> analyzeSelfie({
    required String selfieKey,
    String? selfieUrl,
    int topK = 3,
  }) async {
    final operation = Amplify.API.post(
      '/analyze',
      apiName: _apiName,
      headers: const {'Content-Type': 'application/json'},
      body: HttpPayload.json({
        'selfieKey': selfieKey.trim(),
        if (selfieUrl != null && selfieUrl.trim().isNotEmpty)
          'selfieUrl': selfieUrl.trim(),
        'topK': topK,
      }),
    );

    final response = await operation.response;
    if (response.statusCode >= 400) {
      _throwHttpError(response);
    }

    final decoded = _decodeJsonOrThrow(response.decodeBody());
    _throwIfNotOk(decoded);
    return decoded;
  }

  Future<Map<String, dynamic>> createWearLog({
    required String date,
    String? selfieKey,
    Map<String, String>? selections,
    List<String>? clothesIds,
  }) async {
    final payload = <String, dynamic>{
      'date': date,
      if (selfieKey != null && selfieKey.trim().isNotEmpty)
        'selfieKey': selfieKey.trim(),
      if (selections != null && selections.isNotEmpty) 'selections': selections,
      if (clothesIds != null && clothesIds.isNotEmpty)
        'clothesIds': clothesIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
    };

    final operation = Amplify.API.post(
      '/logs',
      apiName: _apiName,
      headers: const {'Content-Type': 'application/json'},
      body: HttpPayload.json(payload),
    );

    final response = await operation.response;
    if (response.statusCode >= 400) {
      _throwHttpError(response);
    }

    final decoded = _decodeJsonOrThrow(response.decodeBody());
    _throwIfNotOk(decoded);
    return decoded;
  }

  Future<List<Map<String, dynamic>>> listWearLogs({
    String? from,
    String? to,
  }) async {
    final queryParameters = <String, String>{};
    if (from != null && from.trim().isNotEmpty) {
      queryParameters['from'] = from.trim();
    }
    if (to != null && to.trim().isNotEmpty) {
      queryParameters['to'] = to.trim();
    }

    final operation = Amplify.API.get(
      '/logs',
      apiName: _apiName,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await operation.response;
    if (response.statusCode >= 400) {
      _throwHttpError(response);
    }

    final decoded = _decodeJsonOrThrow(response.decodeBody());
    _throwIfNotOk(decoded);

    final items = decoded['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}
