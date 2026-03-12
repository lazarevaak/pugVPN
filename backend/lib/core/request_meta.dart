import 'dart:math';

import 'package:dart_frog/dart_frog.dart';

class RequestMeta {
  RequestMeta({
    required this.requestId,
    required this.clientIp,
    required this.userAgent,
  });

  factory RequestMeta.fromRequest(Request request) {
    final headers = request.headers;
    final forwardedFor = headers['x-forwarded-for'];
    final clientIp = forwardedFor != null && forwardedFor.trim().isNotEmpty
        ? forwardedFor.split(',').first.trim()
        : (headers['x-real-ip']?.trim().isNotEmpty ?? false)
        ? headers['x-real-ip']!.trim()
        : 'unknown';

    final requestIdHeader = headers['x-request-id']?.trim();
    final requestId = requestIdHeader != null && requestIdHeader.isNotEmpty
        ? requestIdHeader
        : _newRequestId();

    return RequestMeta(
      requestId: requestId,
      clientIp: clientIp,
      userAgent: headers['user-agent']?.trim() ?? 'unknown',
    );
  }

  final String requestId;
  final String clientIp;
  final String userAgent;

  static String _newRequestId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random.secure().nextInt(1 << 32).toRadixString(16);
    return 'req_$ts$rnd';
  }
}
