import 'dart:convert';
import 'dart:typed_data';

class DeviceApp {
  const DeviceApp({
    required this.packageName,
    required this.label,
    this.iconBytes,
  });

  final String packageName;
  final String label;
  final Uint8List? iconBytes;

  factory DeviceApp.fromMap(Map<Object?, Object?> map) {
    final iconBase64 = map['iconBase64'] as String?;
    return DeviceApp(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
      iconBytes: iconBase64 == null || iconBase64.isEmpty
          ? null
          : base64Decode(iconBase64),
    );
  }
}
