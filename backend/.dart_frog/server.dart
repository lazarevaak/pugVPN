// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/health.dart' as health;
import '../routes/vpn/servers.dart' as vpn_servers;
import '../routes/vpn/config.dart' as vpn_config;
import '../routes/session/heartbeat.dart' as session_heartbeat;
import '../routes/devices/index.dart' as devices_index;
import '../routes/auth/login.dart' as auth_login;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('127.0.0.1') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/vpn', (context) => buildVpnHandler()(context))
    ..mount('/session', (context) => buildSessionHandler()(context))
    ..mount('/devices', (context) => buildDevicesHandler()(context))
    ..mount('/auth', (context) => buildAuthHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/health', (context) => health.onRequest(context,))..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildVpnHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/config', (context) => vpn_config.onRequest(context,))..all('/servers', (context) => vpn_servers.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildSessionHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/heartbeat', (context) => session_heartbeat.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildDevicesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => devices_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/login', (context) => auth_login.onRequest(context,));
  return pipeline.addHandler(router);
}

