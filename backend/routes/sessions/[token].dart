// ignore_for_file: file_names

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/sessions/revoke_session_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';

Future<Response> onRequest(RequestContext context, String token) async {
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

  final revokeSessionUseCase = context.read<RevokeSessionUseCase>();
  final requestMeta = context.read<RequestMeta>();
  final revoked = await revokeSessionUseCase.execute(
    userId: userId,
    token: token,
    requestMeta: requestMeta,
  );

  if (!revoked) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Session not found.'},
    );
  }

  return Response.json(body: {'ok': true, 'revoked_token': token});
}
