import 'package:pug_vpn_backend/core/request_meta.dart';
import 'package:pug_vpn_backend/domain/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<Map<String, dynamic>> execute({
    required String email,
    required String password,
    required RequestMeta requestMeta,
  }) {
    return _authRepository.login(
      email: email,
      password: password,
      requestMeta: requestMeta,
    );
  }
}
