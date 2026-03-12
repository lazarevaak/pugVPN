import 'package:dart_frog/dart_frog.dart';
import 'package:pug_vpn_backend/domain/repositories/auth_repository.dart';

String? resolveBearerToken(RequestContext context) {
  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || authHeader.isEmpty) return null;

  final parts = authHeader.split(' ');
  if (parts.length != 2 || parts.first.toLowerCase() != 'bearer') return null;

  final token = parts.last.trim();
  if (token.isEmpty) return null;
  return token;
}

Future<String?> resolveUserId(RequestContext context) async {
  final token = resolveBearerToken(context);
  if (token == null) return null;
  final repository = context.read<AuthRepository>();
  return repository.resolveUserIdByToken(token);
}
