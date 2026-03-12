import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/devices/reissue_device_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';
import 'package:pug_vpn_backend/core/exceptions/backend_exception.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/core/validators.dart';

Future<Response> onRequest(RequestContext context, String id) async {
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

  final deviceIdError = validateDeviceId(id);
  if (deviceIdError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': deviceIdError},
    );
  }

  final payload = await context.request.json();
  if (payload is! Map<String, dynamic>) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid JSON payload.'},
    );
  }

  final publicKey = (payload['device_public_key'] as String?)?.trim() ?? '';
  final deviceName = (payload['device_name'] as String?)?.trim();

  final publicKeyError = validatePublicKey(
    publicKey,
    field: 'device_public_key',
  );
  if (publicKeyError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': publicKeyError},
    );
  }
  if (deviceName != null && deviceName.isNotEmpty) {
    final deviceNameError = validateDeviceName(deviceName);
    if (deviceNameError != null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': deviceNameError},
      );
    }
  }

  final reissueDeviceUseCase = context.read<ReissueDeviceUseCase>();
  final requestMeta = context.read<RequestMeta>();

  try {
    final result = await reissueDeviceUseCase.execute(
      userId: userId,
      deviceId: id,
      devicePublicKey: publicKey,
      deviceName: deviceName,
      requestMeta: requestMeta,
    );
    return Response.json(body: result);
  } on DeviceNotFoundException {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Device not found.'},
    );
  } on DeviceRevokedException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': 'Device is revoked and cannot be reissued.'},
    );
  } on DuplicateDeviceKeyException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': error.message},
    );
  } on ServerPreflightException catch (error) {
    return Response.json(
      statusCode: HttpStatus.serviceUnavailable,
      body: {
        'error': error.message,
        'server_preflight': error.preflight.toJson(),
      },
    );
  } on PeerProvisionException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badGateway,
      body: {'error': 'Peer reissue failed.', 'details': error.message},
    );
  }
}
