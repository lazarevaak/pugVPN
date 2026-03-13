class DeviceApp {
  const DeviceApp({
    required this.packageName,
    required this.label,
  });

  final String packageName;
  final String label;

  factory DeviceApp.fromMap(Map<Object?, Object?> map) {
    return DeviceApp(
      packageName: (map['packageName'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
    );
  }
}
