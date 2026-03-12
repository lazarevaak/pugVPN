import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/data/dao/backend_store_dao.dart';
import 'package:pug_vpn_backend/domain/entities/user_account.dart';
import 'package:pug_vpn_backend/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required BackendStoreDao storeDao})
    : _storeDao = storeDao;

  final BackendStoreDao _storeDao;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required RequestMeta requestMeta,
  }) {
    return _storeDao.login(
      email: email,
      password: password,
      requestMeta: requestMeta,
    );
  }

  @override
  Future<String?> resolveUserIdByToken(String token) {
    return _storeDao.resolveUserIdByToken(token);
  }

  @override
  Future<UserAccount?> getUserByToken(String token) {
    return _storeDao.getUserByToken(token);
  }
}
