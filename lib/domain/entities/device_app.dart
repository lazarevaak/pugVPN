import 'dart:convert';
import 'dart:typed_data';

class DeviceApp {
  const DeviceApp({
    required this.packageName,
    required this.label,
    this.sourcePath,
    this.iconBytes,
  });

  final String packageName;
  final String label;
  final String? sourcePath;
  final Uint8List? iconBytes;

  factory DeviceApp.fromMap(Map<Object?, Object?> map) {
    final iconBase64 = map['iconBase64'] as String?;
    return DeviceApp(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
      sourcePath: map['sourcePath'] as String?,
      iconBytes: iconBase64 == null || iconBase64.isEmpty
          ? null
          : base64Decode(iconBase64),
    );
  }

  DeviceApp copyWith({
    String? packageName,
    String? label,
    String? sourcePath,
    Uint8List? iconBytes,
    bool clearIcon = false,
  }) {
    return DeviceApp(
      packageName: packageName ?? this.packageName,
      label: label ?? this.label,
      sourcePath: sourcePath ?? this.sourcePath,
      iconBytes: clearIcon ? null : (iconBytes ?? this.iconBytes),
    );
  }

  Map<String, String> toMap() {
    return <String, String>{
      'packageName': packageName,
      'label': label,
      'sourcePath': sourcePath ?? '',
      'iconBase64': iconBytes == null ? '' : base64Encode(iconBytes!),
    };
  }
}
