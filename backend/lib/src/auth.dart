import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/src/app_store.dart';

String? resolveUserId(RequestContext context) {
  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || authHeader.isEmpty) return null;

  final parts = authHeader.split(' ');
  if (parts.length != 2 || parts.first.toLowerCase() != 'bearer') return null;

  final token = parts.last.trim();
  if (token.isEmpty) return null;

  final store = context.read<AppStore>();
  return store.resolveUserIdByToken(token);
}
