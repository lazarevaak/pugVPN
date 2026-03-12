import 'dart:convert';

String? validateEmail(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized.length > 254) {
    return 'email is required.';
  }

  const pattern = r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$";
  final regex = RegExp(pattern, caseSensitive: false);
  if (!regex.hasMatch(normalized)) {
    return 'email format is invalid.';
  }

  return null;
}

String? validatePassword(String value) {
  if (value.isEmpty) return 'password is required.';
  if (value.length > 1024) return 'password is too long.';
  return null;
}

String? validateServerId(String value) {
  return _validateToken(value, field: 'server_id');
}

String? validateDeviceId(String value) {
  return _validateToken(value, field: 'device_id');
}

String? validateDeviceName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'device_name is required.';
  if (trimmed.length > 80) return 'device_name is too long.';

  const pattern = r"^[A-Za-z0-9 _().#-]+$";
  if (!RegExp(pattern).hasMatch(trimmed)) {
    return 'device_name contains unsupported characters.';
  }

  return null;
}

String? validatePublicKey(String value, {String field = 'public_key'}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '$field is required.';

  try {
    final decoded = base64Decode(trimmed);
    if (decoded.length != 32) {
      return '$field must decode to 32 bytes.';
    }
  } catch (_) {
    return '$field must be valid base64.';
  }

  return null;
}

String? validateLatencyMs(int value) {
  if (value < 0 || value > 600000) {
    return 'latency_ms must be between 0 and 600000.';
  }
  return null;
}

String? _validateToken(String value, {required String field}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '$field is required.';
  if (trimmed.length > 128) return '$field is too long.';

  const pattern = r'^[A-Za-z0-9_.:-]+$';
  if (!RegExp(pattern).hasMatch(trimmed)) {
    return '$field contains unsupported characters.';
  }

  return null;
}
