import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();

  // Use secure storage on mobile, shared_preferences on web
  final FlutterSecureStorage? _secureStorage =
  kIsWeb ? null : const FlutterSecureStorage();
  SharedPreferences? _sharedPrefs;

  // Storage keys
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _emailKey = 'email';
  static const _isActiveKey = 'is_active';

  factory UserSessionService() => _instance;

  UserSessionService._internal();

  String? _token;
  int? _userId;
  String? _username;
  String? _email;
  bool? _isActive;

  // Initialize storage
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        _sharedPrefs = await SharedPreferences.getInstance();
      }
      await _loadFromStorage();
    } catch (e) {
      debugPrint('Storage initialization error: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    _token = await _readFromStorage(_tokenKey);
    final userIdStr = await _readFromStorage(_userIdKey);
    _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
    _username = await _readFromStorage(_usernameKey);
    _email = await _readFromStorage(_emailKey);
    final isActiveStr = await _readFromStorage(_isActiveKey);
    _isActive = isActiveStr != null ? isActiveStr.toLowerCase() == 'true' : null;
  }

  Future<String?> _readFromStorage(String key) async {
    if (kIsWeb) {
      return _sharedPrefs?.getString(key);
    } else {
      return await _secureStorage?.read(key: key);
    }
  }

  Future<void> _writeToStorage(String key, String? value) async {
    try {
      if (kIsWeb) {
        if (value != null) {
          await _sharedPrefs?.setString(key, value);
        } else {
          await _sharedPrefs?.remove(key);
        }
      } else {
        if (value != null) {
          await _secureStorage?.write(key: key, value: value);
        } else {
          await _secureStorage?.delete(key: key);
        }
      }
    } catch (e) {
      debugPrint('Error writing to storage: $e');
    }
  }

  String? get token => _token;
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  bool? get isActive => _isActive;
  bool get isLoggedIn => _token != null && _isActive == true;

  Map<String, dynamic> decodeToken(String token) {
    try {
      if (token.isEmpty) {
        throw Exception('Token is empty');
      }
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid JWT token format');
      }

      final decoded = JwtDecoder.decode(token);

      if (decoded['userId'] == null) {
        throw Exception('Token missing required user ID');
      }

      return decoded;
    } catch (e) {
      debugPrint('Token decoding failed: $e');
      rethrow;
    }
  }

  Future<void> setUserData(Map<String, dynamic> data) async {
    if (data['token'] != null) {
      await setAuthToken(data['token']);
    }

    if (_token != null) {
      final decoded = JwtDecoder.decode(_token!);
      _userId = _tryParseInt(decoded['userId']);
      _username = decoded['name']?.toString();
      _email = decoded['email']?.toString();
      _isActive = _tryParseBool(decoded['isActive']);
    } else {
      _userId = _tryParseInt(data['userId']);
      _username = data['name']?.toString();
      _email = data['email']?.toString();
      _isActive = _tryParseBool(data['isActive']);
    }

    await _writeToStorage(_userIdKey, _userId?.toString());
    await _writeToStorage(_usernameKey, _username);
    await _writeToStorage(_emailKey, _email);
    await _writeToStorage(_isActiveKey, _isActive?.toString());
  }

  Future<void> setAuthToken(String token) async {
    _token = token;
    await _writeToStorage(_tokenKey, token);
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _username = null;
    _email = null;
    _isActive = null;

    await _writeToStorage(_tokenKey, null);
    await _writeToStorage(_userIdKey, null);
    await _writeToStorage(_usernameKey, null);
    await _writeToStorage(_emailKey, null);
    await _writeToStorage(_isActiveKey, null);
  }

  // Helper methods
  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _tryParseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return null;
  }
}