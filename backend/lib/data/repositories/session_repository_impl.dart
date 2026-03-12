import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/data/dao/backend_store_dao.dart';
import 'package:pug_vpn_backend/domain/entities/user_session.dart';
import 'package:pug_vpn_backend/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required BackendStoreDao storeDao})
    : _storeDao = storeDao;

  final BackendStoreDao _storeDao;

  @override
  Future<List<UserSession>> listSessions({required String userId}) {
    return _storeDao.listSessions(userId: userId);
  }

  @override
  Future<bool> revokeSessionByToken({
    required String userId,
    required String token,
    required RequestMeta requestMeta,
  }) {
    return _storeDao.revokeSessionByToken(
      userId: userId,
      token: token,
      requestMeta: requestMeta,
    );
  }
}
