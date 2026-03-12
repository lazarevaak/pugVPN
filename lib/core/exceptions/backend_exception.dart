class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}
