import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class CalendarLinkResponse {
  CalendarLinkResponse({
    required this.redirectUrl,
    this.linkToken,
  });

  final String redirectUrl;
  final String? linkToken;

  factory CalendarLinkResponse.fromJson(Map<String, dynamic> json) {
    final url = json['redirectUrl'] as String? ?? json['redirect_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const FormatException('Missing redirectUrl in link response');
    }
    return CalendarLinkResponse(
      redirectUrl: url,
      linkToken: json['linkToken'] as String? ?? json['link_token'] as String?,
    );
  }
}

class CalendarStatusResponse {
  CalendarStatusResponse({
    required this.connected,
    this.connectedAccountId,
    this.status,
  });

  final bool connected;
  final String? connectedAccountId;
  final String? status;

  factory CalendarStatusResponse.fromJson(Map<String, dynamic> json) {
    return CalendarStatusResponse(
      connected: json['connected'] as bool? ?? false,
      connectedAccountId:
          json['connectedAccountId'] as String? ?? json['connected_account_id'] as String?,
      status: json['status'] as String?,
    );
  }
}

/// Calls the app backend only (never Composio keys in the client).
class CalendarBackendClient {
  CalendarBackendClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<CalendarLinkResponse> requestGoogleCalendarLink(String userId) async {
    final res = await _http.post(
      _uri('/v1/integrations/google-calendar/link'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = body is Map && body['error'] != null
          ? body['error'].toString()
          : res.body;
      throw CalendarBackendException(res.statusCode, msg);
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON from link endpoint');
    }
    return CalendarLinkResponse.fromJson(body);
  }

  Future<CalendarStatusResponse> getGoogleCalendarStatus(String userId) async {
    final res = await _http.get(
      _uri('/v1/integrations/google-calendar/status', {'userId': userId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = body is Map && body['error'] != null
          ? body['error'].toString()
          : res.body;
      throw CalendarBackendException(res.statusCode, msg);
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON from status endpoint');
    }
    return CalendarStatusResponse.fromJson(body);
  }

  void close() => _http.close();
}

class CalendarBackendException implements Exception {
  CalendarBackendException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'CalendarBackendException($statusCode): $message';
}
