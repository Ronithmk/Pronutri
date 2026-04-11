import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _fallbackBaseUrl = 'http://13.203.173.93/api';
  static const _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _fallbackBaseUrl,
  );
  static final String baseUrl = _normalizeBaseUrl(_rawBaseUrl);

  static String get backendOrigin {
    final uri = Uri.parse(baseUrl);
    final apiIndex = uri.path.indexOf('/api');
    var path = apiIndex >= 0 ? uri.path.substring(0, apiIndex) : uri.path;
    path = _stripTrailingSlashes(path);
    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  static String absoluteUrl(String pathOrUrl) {
    final trimmed = pathOrUrl.trim();
    if (trimmed.isEmpty) return backendOrigin;
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) return trimmed;
    final normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$backendOrigin$normalizedPath';
  }

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response r) {
    final status = r.statusCode;
    try {
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) {
        if (status >= 400 && !body.containsKey('error')) {
          return {'error': 'Request failed ($status)'};
        }
        return body;
      }
      if (status >= 400) return {'error': 'Request failed ($status)'};
      return {'data': body, 'status': status};
    } catch (_) {
      if (status >= 400) return {'error': 'Request failed ($status)'};
      return {'error': 'Server error ($status)'};
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map body) async {
    final r = await http
        .post(
          _uriForPath(path),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(r);
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final r = await http
        .get(
          _uriForPath(path),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(r);
  }

  // ── Multipart file upload ─────────────────────────────────────────────────
  // Sends a multipart POST with [filePath] under [fieldName] plus optional
  // string [fields]. The caller's JWT is attached automatically.
  static Future<Map<String, dynamic>> uploadFile(
    String path,
    String filePath, {
    Map<String, String>? fields,
    String fieldName = 'document',
  }) async {
    final token = await _token();
    final request = http.MultipartRequest(
      'POST',
      _uriForPath(path),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  // ── Authenticated raw bytes fetch ─────────────────────────────────────────
  // Used to load protected images (e.g. trainer documents) with the JWT token.
  static Future<Uint8List?> getBytes(String url) async {
    final token = await _token();
    try {
      final r = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) return r.bodyBytes;
    } catch (_) {}
    return null;
  }

  static Uri _uriForPath(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String _normalizeBaseUrl(String candidate) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return _fallbackBaseUrl;

    final withoutTrailingSlashes = _stripTrailingSlashes(trimmed);
    final uri = Uri.tryParse(withoutTrailingSlashes);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return _fallbackBaseUrl;
    }

    var path = _stripTrailingSlashes(uri.path);
    if (path.isEmpty) {
      path = '/api';
    } else {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      if (!segments.contains('api')) {
        path = '$path/api';
      }
    }

    return uri.replace(path: path, query: null, fragment: null).toString();
  }

  static String _stripTrailingSlashes(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
