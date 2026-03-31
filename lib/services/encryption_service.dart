import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'dart:math';


class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _privateKeyTag = 'rsa_private_key';

  // 1. RSA Key Generation
  Future<Map<String, String>> generateRSAKeys() async {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _getSecureRandom(),
      ));


    final pair = keyGen.generateKeyPair();
    final public = pair.publicKey as RSAPublicKey;
    final private = pair.privateKey as RSAPrivateKey;

    // Convert to PEM-friendly format (simplified for this app's storage)
    String pubStr = base64Encode(utf8.encode("${public.modulus}:${public.exponent}"));
    String privStr = base64Encode(utf8.encode("${private.modulus}:${private.privateExponent}:${private.p}:${private.q}"));

    await _storage.write(key: _privateKeyTag, value: privStr);
    return {'publicKey': pubStr};
  }

  // 2. AES Key Generation (for sessions)
  String generateAESKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }

  // 3. AES Encryption
  String encryptAES(String plainText, String base64Key) {
    final key = encrypt.Key.fromBase64(base64Key);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  // 4. AES Decryption
  String decryptAES(String cipherText, String base64Key) {
    final parts = cipherText.split(':');
    if (parts.length != 2) return cipherText; // Fallback

    
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = encrypt.Key.fromBase64(base64Key);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  // 5. RSA Encryption (for key exchange)
  String encryptRSA(String plainText, String publicKeyStr) {
    final decoded = utf8.decode(base64Decode(publicKeyStr)).split(':');
    final public = RSAPublicKey(BigInt.parse(decoded[0]), BigInt.parse(decoded[1]));
    
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: public));
    return encrypter.encrypt(plainText).base64;
  }

  // 6. RSA Decryption (for key exchange)
  Future<String> decryptRSA(String cipherText) async {
    final privStr = await _storage.read(key: _privateKeyTag);
    if (privStr == null) return cipherText;

    final decoded = utf8.decode(base64Decode(privStr)).split(':');
    final private = RSAPrivateKey(
      BigInt.parse(decoded[0]),
      BigInt.parse(decoded[1]),
      BigInt.parse(decoded[2]),
      BigInt.parse(decoded[3]),
    );

    final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: private));
    return encrypter.decrypt(encrypt.Encrypted.fromBase64(cipherText));
  }

  FortunaRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}
