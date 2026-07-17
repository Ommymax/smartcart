import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/user.dart';
import '../../shared/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api);

  final ApiService api;
  AppUser? user;
  String? token;
  bool loading = false;
  String? error;

  String? get userRole => user?.role;
  bool get isAuthenticated => token != null;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    api.baseUrl = prefs.getString(AppConstants.apiBaseUrlKey) ?? AppConfig.defaultApiBaseUrl;
    token = prefs.getString(AppConstants.tokenKey);
    api.token = token;
    if (token != null) {
      try {
        final response = await api.get('/api/auth/me');
        user = AppUser.fromJson(response['user']);
      } catch (_) {
        await logout();
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.post('/api/auth/login', {'email': email, 'password': password});
      token = response['token'];
      user = AppUser.fromJson(response['user']);
      api.token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token!);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.post('/api/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });
      token = response['token'];
      user = AppUser.fromJson(response['user']);
      api.token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token!);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    user = null;
    api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    notifyListeners();
  }

  Future<void> saveApiBaseUrl(String value) async {
    api.baseUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiBaseUrlKey, value);
    notifyListeners();
  }
}
