import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

class ClothesApiService {
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
    throw ApiException('HTTP $status\n$body');
  }

  Future<List<Map<String, dynamic>>> listClothes({
    String? category,
    String? color,
    String? categoryColor,
  }) async {
    final queryParameters = <String, String>{};
    if (categoryColor != null && categoryColor.trim().isNotEmpty) {
      queryParameters['categoryColor'] = categoryColor.trim();
    } else {
      if (category != null && category.trim().isNotEmpty) {
        queryParameters['category'] = category.trim();
      }
      if (color != null && color.trim().isNotEmpty) {
        queryParameters['color'] = color.trim();
      }
    }

    final operation = Amplify.API.get(
      '/clothes',
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

  Future<Map<String, dynamic>> getClothes(String clothesId) async {
    final id = clothesId.trim();
    final operation = Amplify.API.get('/clothes/$id', apiName: _apiName);
    final response = await operation.response;
    if (response.statusCode >= 400) {
      _throwHttpError(response);
    }
    final decoded = _decodeJsonOrThrow(response.decodeBody());
    _throwIfNotOk(decoded);

    final item = decoded['item'];
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    throw const FormatException('Invalid response: item');
  }

  Future<Map<String, dynamic>> createClothes({
    required String category,
    String? subCategory,
    required String color,
    String? sleeveLength,
    String? hemLength,
    List<String>? season,
    String? scene,
    String? imageUrl,
    String? name,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'category': category.trim(),
      if (subCategory != null && subCategory.trim().isNotEmpty) 'subCategory': subCategory.trim(),
      'color': color.trim(),
      if (sleeveLength != null && sleeveLength.trim().isNotEmpty) 'sleeveLength': sleeveLength.trim(),
      if (hemLength != null && hemLength.trim().isNotEmpty) 'hemLength': hemLength.trim(),
      if (season != null && season.where((e) => e.trim().isNotEmpty).isNotEmpty)
        'season': season.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      if (scene != null && scene.trim().isNotEmpty) 'scene': scene.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final operation = Amplify.API.post(
      '/clothes',
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

    final item = decoded['item'];
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    throw const FormatException('Invalid response: item');
  }

  Future<Map<String, dynamic>> updateClothes(
    String clothesId, {
    String? category,
    String? subCategory,
    String? color,
    String? sleeveLength,
    String? hemLength,
    List<String>? season,
    String? scene,
    String? imageUrl,
    String? name,
    String? notes,
  }) async {
    final id = clothesId.trim();
    final payload = <String, dynamic>{
      if (category != null) 'category': category.trim(),
      if (subCategory != null) 'subCategory': subCategory.trim(),
      if (color != null) 'color': color.trim(),
      if (sleeveLength != null) 'sleeveLength': sleeveLength.trim(),
      if (hemLength != null) 'hemLength': hemLength.trim(),
      if (season != null) 'season': season.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      if (scene != null) 'scene': scene.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl.trim(),
      if (name != null) 'name': name.trim(),
      if (notes != null) 'notes': notes.trim(),
    };

    final operation = Amplify.API.put(
      '/clothes/$id',
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

    final item = decoded['item'];
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    throw const FormatException('Invalid response: item');
  }

  Future<void> deleteClothes(String clothesId) async {
    final id = clothesId.trim();
    final operation = Amplify.API.delete('/clothes/$id', apiName: _apiName);
    final response = await operation.response;
    if (response.statusCode >= 400) {
      _throwHttpError(response);
    }
    final decoded = _decodeJsonOrThrow(response.decodeBody());
    _throwIfNotOk(decoded);
  }

  void _throwIfNotOk(Map<String, dynamic> decoded) {
    final ok = decoded['ok'];
    if (ok == true) {
      return;
    }
    final error = decoded['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException(error);
    }
    throw const ApiException('API error');
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
