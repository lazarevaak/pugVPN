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

  final deviceName = (payload['device_name'] as String?)?.trim() ?? '';
  final publicKey = (payload['public_key'] as String?)?.trim() ?? '';
  final serverId = (payload['server_id'] as String?)?.trim();

  if (deviceName.isEmpty || publicKey.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'device_name and public_key are required.'},
    );
  }

  final store = context.read<AppStore>();

  try {
    final server = store.resolveServer(serverId: serverId);
    final device = store.registerDevice(
      userId: userId,
      serverId: server.id,
      deviceName: deviceName,
      publicKey: publicKey,
      subnet: server.subnet,
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'device': device.toJson()},
    );
  } on ServerNotFoundException {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Server not found.'},
    );
  } on TooManyClientsException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': 'No free addresses for this user.'},
    );
  }
}
