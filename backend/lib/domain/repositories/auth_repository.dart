import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/entities/user_account.dart';

abstract interface class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required RequestMeta requestMeta,
  });

  Future<String?> resolveUserIdByToken(String token);

  Future<UserAccount?> getUserByToken(String token);
}
