import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/application/use_cases/servers/list_servers_use_case.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final listServersUseCase = context.read<ListServersUseCase>();
  final servers = await listServersUseCase.execute();
  return Response.json(
    body: {'servers': servers.map((s) => s.toJson()).toList()},
  );
}
