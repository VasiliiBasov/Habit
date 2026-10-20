import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранилище JWT-токена (Keychain на iOS / EncryptedSharedPreferences на Android).
class TokenStorage {
  static const _key = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
