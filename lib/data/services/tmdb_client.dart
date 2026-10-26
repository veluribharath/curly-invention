import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TmdbException implements Exception {
  final int? statusCode;
  final String message;

  const TmdbException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null ? 'TMDB: $message' : 'TMDB error $statusCode: $message';
}

/// Sends authenticated GET requests to the TMDB v3 API and decodes the JSON.
///
/// Takes a v3 API key (sent as `api_key`) or a v4 read access token (a JWT,
/// sent as a bearer token); which one is told apart by the "ey" prefix.
class TmdbClient {
  static const baseUrl = 'https://api.themoviedb.org/3';

  /// TMDB refuses pages past 500 on its list and discover endpoints.
  static const maxPage = 500;

  final String apiKey;
  final http.Client _http;

  /// How long a request may take before it fails, so a hung request doesn't
  /// leave a screen loading with no way to retry.
  final Duration timeout;

  TmdbClient({required String apiKey, http.Client? httpClient, this.timeout = const Duration(seconds: 15)})
    : apiKey = apiKey.trim(),
      _http = httpClient ?? http.Client();

  bool get _isBearer => apiKey.startsWith('ey');

  Uri uri(String path, [Map<String, String> query = const {}]) {
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: {...query, if (!_isBearer && apiKey.isNotEmpty) 'api_key': apiKey});
  }

  Future<Map<String, dynamic>> get(String path, [Map<String, String> query = const {}]) async {
    if (apiKey.isEmpty) {
      throw const TmdbException('TMDB_API_KEY not set. Run with --dart-define=TMDB_API_KEY=...');
    }
    final http.Response res;
    try {
      res = await _http
          .get(
            uri(path, query),
            headers: {'accept': 'application/json', if (_isBearer) 'Authorization': 'Bearer $apiKey'},
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const TmdbException('Request timed out');
    }
    if (res.statusCode != 200) {
      throw TmdbException(_statusMessage(res.body), statusCode: res.statusCode);
    }
    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const TmdbException('Unexpected response');
    }
    return decoded;
  }

  static String _statusMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['status_message'] is String) return decoded['status_message'] as String;
    } on FormatException {
      // Not JSON; fall through to the raw body.
    }
    return body.length > 200 ? body.substring(0, 200) : body;
  }
}
