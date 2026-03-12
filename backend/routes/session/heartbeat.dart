import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/push_heartbeat_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';
import 'package:pug_vpn_backend/core/validators.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = await resolveUserId(context);
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

  final deviceIdError = validateDeviceId(deviceId);
  if (deviceIdError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': deviceIdError},
    );
  }
  final serverIdError = validateServerId(serverId);
  if (serverIdError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': serverIdError},
    );
  }
  final latencyError = validateLatencyMs(latencyMs);
  if (latencyError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': latencyError},
    );
  }

  final pushHeartbeatUseCase = context.read<PushHeartbeatUseCase>();
  await pushHeartbeatUseCase.execute(
    userId: userId,
    deviceId: deviceId,
    serverId: serverId,
    isConnected: isConnected,
    latencyMs: latencyMs,
  );

  return Response.json(body: {'ok': true});
}
