import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/auth/get_current_user_use_case.dart';
import 'package:pug_vpn_backend/core/auth.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final token = resolveBearerToken(context);
  if (token == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Bearer token is required.'},
    );
  }

  final getCurrentUserUseCase = context.read<GetCurrentUserUseCase>();
  final result = await getCurrentUserUseCase.execute(token: token);
  if (result == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Session is invalid or expired.'},
    );
  }

  return Response.json(body: result);
}
