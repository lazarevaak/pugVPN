import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/src/app_store.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final store = context.read<AppStore>();
  return Response.json(
    body: {'servers': store.listServers().map((s) => s.toJson()).toList()},
  );
}
