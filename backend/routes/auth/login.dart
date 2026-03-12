import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/auth/login_use_case.dart';
import 'package:pug_vpn_backend/core/exceptions/backend_exception.dart';
import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/core/validators.dart';

Future<Response> onRequest(RequestContext context) async {
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

  final email = (payload['email'] as String?)?.trim() ?? '';
  final password = (payload['password'] as String?) ?? '';

  final emailError = validateEmail(email);
  if (emailError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': emailError},
    );
  }
  final passwordError = validatePassword(password);
  if (passwordError != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': passwordError},
    );
  }

  final loginUseCase = context.read<LoginUseCase>();
  final requestMeta = context.read<RequestMeta>();

  try {
    final result = await loginUseCase.execute(
      email: email,
      password: password,
      requestMeta: requestMeta,
    );
    return Response.json(body: result);
  } on RateLimitExceededException catch (error) {
    return Response.json(
      statusCode: HttpStatus.tooManyRequests,
      headers: {'retry-after': '${error.retryAfterSeconds}'},
      body: {
        'error': 'Too many login attempts.',
        'retry_after_seconds': error.retryAfterSeconds,
      },
    );
  } on InvalidCredentialsException {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Invalid credentials.'},
    );
  }
}
