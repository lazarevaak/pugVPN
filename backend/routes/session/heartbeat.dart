import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/src/app_store.dart';
import 'package:pug_vpn_backend/src/auth.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = resolveUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Bearer token is required.'},
    );
  }

  final payload = await context.request.json();
  if (payload is! Map<String, dynamic>) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid JSON payload.'},
    );
  }

  final deviceId = (payload['device_id'] as String?)?.trim() ?? '';
  final serverId = (payload['server_id'] as String?)?.trim() ?? '';
  final isConnected = (payload['is_connected'] as bool?) ?? false;
  final latencyMs = (payload['latency_ms'] as num?)?.toInt() ?? 0;

  if (deviceId.isEmpty || serverId.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'device_id and server_id are required.'},
    );
  }

  final store = context.read<AppStore>();
  store.pushHeartbeat(
    userId: userId,
    deviceId: deviceId,
    serverId: serverId,
    isConnected: isConnected,
    latencyMs: latencyMs,
  );

  return Response.json(body: {'ok': true});
}
