import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/src/app_store.dart';

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

  if (email.isEmpty || password.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'email and password are required.'},
    );
  }

  final store = context.read<AppStore>();

  try {
    final result = store.login(email: email, password: password);
    return Response.json(body: result);
  } on InvalidCredentialsException {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Invalid credentials.'},
    );
  }
}
