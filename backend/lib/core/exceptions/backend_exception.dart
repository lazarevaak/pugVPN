import 'package:pug_vpn_backend/domain/entities/server_preflight.dart';

class InvalidCredentialsException implements Exception {}

class RateLimitExceededException implements Exception {
  RateLimitExceededException(this.retryAfterSeconds);

  final int retryAfterSeconds;
}

class ServerNotFoundException implements Exception {}

class DeviceNotFoundException implements Exception {}

class DeviceRevokedException implements Exception {}

class DuplicateDeviceKeyException implements Exception {
  DuplicateDeviceKeyException(this.message);

  final String message;
}

class TooManyClientsException implements Exception {}

class PeerProvisionException implements Exception {
  PeerProvisionException(this.message);

  final String message;

  @override
  String toString() => 'PeerProvisionException: $message';
}

class ServerPreflightException implements Exception {
  ServerPreflightException({required this.message, required this.preflight});

  final String message;
  final ServerPreflight preflight;

  @override
  String toString() => 'ServerPreflightException: $message';
}

class StorageException implements Exception {
  StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}
