import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class ApiClient {
  ApiClient();

  String? _token;

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Uri _uri(String path) {
    final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Map<String, String> _headers({bool auth = true, bool json = true}) {
    final h = <String, String>{
      'Accept': 'application/json',
    };
    if (json) h['Content-Type'] = 'application/json';
    if (auth && _token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove('access_token');
    } else {
      await prefs.setString('access_token', token);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic>? body, {
    bool auth = true,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    if (_token != null) {
      req.headers['Authorization'] = 'Bearer $_token';
    }
    req.headers['Accept'] = 'application/json';
    req.fields.addAll(fields);
    req.files.addAll(files);
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic>? body,
  ) async {
    final res = await http.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final res = await http.get(_uri(path), headers: _headers(auth: auth));
    return _decode(res);
  }

  Future<List<dynamic>> getList(String path, {bool auth = true}) async {
    final res = await http.get(_uri(path), headers: _headers(auth: auth));
    if (res.statusCode >= 400) {
      _decode(res); // throws
    }
    if (res.body.isEmpty || res.body == 'null') return [];
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['_data'] is List) {
      return decoded['_data'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers());
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty && res.body != 'null') {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else if (decoded is List) {
          json = {'_data': decoded};
        }
      } on FormatException {
        if (res.statusCode == 413) {
          throw ApiException(
            'Arquivo muito grande. Envie fotos menores.',
            res.statusCode,
          );
        }
        throw ApiException(
          'Falha no envio (${res.statusCode}). Tente fotos menores.',
          res.statusCode,
        );
      }
    }
    if (res.statusCode >= 400) {
      final msg = json['message'];
      final text = msg is List
          ? msg.join(', ')
          : (msg?.toString() ?? 'Erro ${res.statusCode}');
      throw ApiException(text, res.statusCode);
    }
    return json;
  }
}

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
