import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/entities/user_session.dart';

abstract interface class SessionRepository {
  Future<List<UserSession>> listSessions({required String userId});

  Future<bool> revokeSessionByToken({
    required String userId,
    required String token,
    required RequestMeta requestMeta,
  });
}
