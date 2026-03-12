import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:pug_vpn/core/exceptions/backend_exception.dart';
import 'package:pug_vpn/data/dto/vpn_config_result_dto.dart';
import 'package:pug_vpn/data/dto/vpn_server_dto.dart';

class BackendApiDao {
  BackendApiDao({required String baseUrl})
    : _baseUri = Uri.parse(baseUrl),
      _http = http.Client();

  final Uri _baseUri;
  final http.Client _http;

  void dispose() {
    _http.close();
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final jsonMap = await _requestJson(
      method: 'POST',
      path: '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    final token = jsonMap['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const BackendException('Backend не вернул access_token.');
    }
    return token;
  }

  Future<List<VpnServerDto>> fetchServers({required String accessToken}) async {
    final jsonMap = await _requestJson(
      method: 'GET',
      path: '/vpn/servers',
      accessToken: accessToken,
    );
    final rawList = jsonMap['servers'];
    if (rawList is! List) {
      throw const BackendException(
        'Backend вернул некорректный список servers.',
      );
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(VpnServerDto.fromJson)
        .toList(growable: false);
  }

  Future<VpnConfigResultDto> buildConfig({
    required String accessToken,
    required String serverId,
    required String deviceName,
    required String devicePublicKey,
  }) async {
    final jsonMap = await _requestJson(
      method: 'POST',
      path: '/vpn/config',
      accessToken: accessToken,
      body: <String, dynamic>{
        'server_id': serverId,
        'device_name': deviceName,
        'device_public_key': devicePublicKey,
      },
    );
    return VpnConfigResultDto.fromJson(jsonMap);
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required String path,
    String? accessToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = _baseUri.resolve(path);
    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (accessToken != null) 'authorization': 'Bearer $accessToken',
    };

    final response = switch (method) {
      'GET' => await _http.get(uri, headers: headers),
      'POST' => await _http.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      _ => throw BackendException('Unsupported method: $method'),
    };

    final decoded = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded['error'] as String? ?? 'HTTP ${response.statusCode}';
      throw BackendException(message);
    }
    return decoded;
  }

  Map<String, dynamic> _decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const BackendException('Backend вернул некорректный JSON.');
    }
    return decoded;
  }
}
