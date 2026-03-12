import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/list_devices_use_case.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/register_device_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';
import 'package:pug_vpn_backend/core/exceptions/backend_exception.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/core/validators.dart';

Future<Response> onRequest(RequestContext context) async {
  final userId = await resolveUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Bearer token is required.'},
    );
  }

  if (context.request.method == HttpMethod.get) {
    final listDevicesUseCase = context.read<ListDevicesUseCase>();
    final includeRevoked =
        context.request.uri.queryParameters['include_revoked'] == '1';
    final devices = await listDevicesUseCase.execute(
      userId: userId,
      includeRevoked: includeRevoked,
    );
    return Response.json(body: {'devices': devices});
  }

  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
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

  final deviceNameError = validateDeviceName(deviceName);
  if (deviceNameError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': deviceNameError},
    );
  }
  final keyError = validatePublicKey(publicKey);
  if (keyError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': keyError},
    );
  }
  if (serverId != null && serverId.isNotEmpty) {
    final serverIdError = validateServerId(serverId);
    if (serverIdError != null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': serverIdError},
      );
    }
  }

  final registerDeviceUseCase = context.read<RegisterDeviceUseCase>();
  final requestMeta = context.read<RequestMeta>();

  try {
    final device = await registerDeviceUseCase.execute(
      userId: userId,
      deviceName: deviceName,
      publicKey: publicKey,
      serverId: serverId,
      requestMeta: requestMeta,
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
  } on DuplicateDeviceKeyException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': error.message},
    );
  } on TooManyClientsException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': 'No free addresses for this user.'},
    );
  }
}
