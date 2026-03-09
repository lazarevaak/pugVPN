import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'service': 'pug_vpn_backend',
      'status': 'ok',
      'endpoints': [
        'GET /health',
        'POST /auth/login',
        'POST /devices',
        'GET /vpn/servers',
        'POST /vpn/config',
        'POST /session/heartbeat',
      ],
    },
  );
}
