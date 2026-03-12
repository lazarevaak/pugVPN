import 'package:pug_vpn_backend/domain/repositories/auth_repository.dart';
import 'package:pug_vpn_backend/domain/repositories/session_repository.dart';

class GetCurrentUserUseCase {
  GetCurrentUserUseCase({
    required AuthRepository authRepository,
    required SessionRepository sessionRepository,
  }) : _authRepository = authRepository,
       _sessionRepository = sessionRepository;

  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;

  Future<Map<String, dynamic>?> execute({required String token}) async {
    final user = await _authRepository.getUserByToken(token);
    if (user == null) {
      return null;
    }

    final sessions = await _sessionRepository.listSessions(userId: user.id);
    return {
      'user': user.toJson(),
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'current_token': token,
    };
  }
}
