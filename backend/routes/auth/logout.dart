import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/auth/logout_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final token = resolveBearerToken(context);
  final userId = await resolveUserId(context);
  if (token == null || userId == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Bearer token is required.'},
    );
  }

  final logoutUseCase = context.read<LogoutUseCase>();
  final requestMeta = context.read<RequestMeta>();
  final revoked = await logoutUseCase.execute(
    userId: userId,
    token: token,
    requestMeta: requestMeta,
  );

  return Response.json(body: {'ok': revoked, 'revoked': revoked});
}
