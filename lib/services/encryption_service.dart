import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final _secureStorage = const FlutterSecureStorage();
  final _keyName = 'encryption_key';

  // Generate a random 32-byte encryption key
  Future<String> _generateKey() async {
    final key = Key.fromSecureRandom(32);
    await _secureStorage.write(key: _keyName, value: key.base64);
    return key.base64;
  }

  // Retrieve the encryption key (or create it if not exists)
  Future<Key> getEncryptionKey() async {
    String? storedKey = await _secureStorage.read(key: _keyName);

    storedKey ??= await _generateKey();

    return Key.fromBase64(storedKey);
  }
}
