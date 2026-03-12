import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class DeviceKeyPair {
  const DeviceKeyPair({
    required this.privateKeyBase64,
    required this.publicKeyBase64,
  });

  final String privateKeyBase64;
  final String publicKeyBase64;

  static Future<DeviceKeyPair> generate() async {
    final keyPair = await X25519().newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = (await keyPair.extractPublicKey()).bytes;
    return DeviceKeyPair(
      privateKeyBase64: base64Encode(privateKey),
      publicKeyBase64: base64Encode(publicKey),
    );
  }
}
