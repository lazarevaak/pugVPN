import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/repositories/session_repository.dart';

class LogoutUseCase {
  LogoutUseCase({required SessionRepository sessionRepository})
    : _sessionRepository = sessionRepository;

  final SessionRepository _sessionRepository;

  Future<bool> execute({
    required String userId,
    required String token,
    required RequestMeta requestMeta,
  }) {
    return _sessionRepository.revokeSessionByToken(
      userId: userId,
      token: token,
      requestMeta: requestMeta,
    );
  }
}
