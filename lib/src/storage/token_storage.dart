// lib/src/storage/token_storage.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_tokens.dart';

abstract class TokenStorage {
  Future<void> saveTokens(AuthTokens tokens);
  Future<AuthTokens?> getTokens();
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;
  final String _tokenKey = 'altair_auth_tokens';

  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    final json = jsonEncode(tokens.toJson());
    await _storage.write(key: _tokenKey, value: json);
  }

  @override
  Future<AuthTokens?> getTokens() async {
    final jsonStr = await _storage.read(key: _tokenKey);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr);
      return AuthTokens.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
  }
}

class MemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<AuthTokens?> getTokens() async {
    return _tokens;
  }

  @override
  Future<void> clearTokens() async {
    _tokens = null;
  }
}
