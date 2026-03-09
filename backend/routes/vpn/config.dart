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

  final serverId = (payload['server_id'] as String?)?.trim() ?? '';
  final deviceName = (payload['device_name'] as String?)?.trim() ?? '';
  final devicePublicKey =
      (payload['device_public_key'] as String?)?.trim() ?? '';

  if (serverId.isEmpty || deviceName.isEmpty || devicePublicKey.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': 'server_id, device_name and device_public_key are required.',
      },
    );
  }

  final store = context.read<AppStore>();

  try {
    final result = store.buildConfig(
      userId: userId,
      serverId: serverId,
      deviceName: deviceName,
      devicePublicKey: devicePublicKey,
    );
    return Response.json(body: result);
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
  } on PeerProvisionException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badGateway,
      body: {'error': 'Peer provisioning failed.', 'details': e.message},
    );
  }
}
