// ignore_for_file: file_names

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/revoke_device_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';
import 'package:pug_vpn_backend/core/exceptions/backend_exception.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/core/validators.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final userId = await resolveUserId(context);
  if (userId == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Bearer token is required.'},
    );
  }

  final deviceIdError = validateDeviceId(id);
  if (deviceIdError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': deviceIdError},
    );
  }

  final revokeDeviceUseCase = context.read<RevokeDeviceUseCase>();
  final requestMeta = context.read<RequestMeta>();

  try {
    final result = await revokeDeviceUseCase.execute(
      userId: userId,
      deviceId: id,
      requestMeta: requestMeta,
    );
    return Response.json(body: result);
  } on DeviceNotFoundException {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Device not found.'},
    );
  } on PeerProvisionException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badGateway,
      body: {'error': 'Peer revocation failed.', 'details': error.message},
    );
  }
}
