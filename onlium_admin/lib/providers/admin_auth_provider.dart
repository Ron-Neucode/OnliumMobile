import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin.dart';

class AdminAuthProvider extends ChangeNotifier {
static const String _baseUrl = 'https://localhost:7164';
  // Android emulator:
  // static const String _baseUrl = 'http://10.0.2.2:5027';
  // Windows desktop:
  // static const String _baseUrl = 'http://localhost:5027';

  Admin? _currentAdmin;
  String? _token;

  bool _isLoading = false;
  String? _errorMessage;

  Admin? get currentAdmin => _currentAdmin;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _currentAdmin != null && _token != null && _token!.isNotEmpty;

  AdminAuthProvider() {
    _loadCurrentAdmin();
  }

  Future<void> _loadCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final currentAdminJson = prefs.getString('currentAdmin');
      final savedToken = prefs.getString('token');

      if (currentAdminJson != null &&
          savedToken != null &&
          savedToken.isNotEmpty) {
        _currentAdmin = Admin.fromJson(
          Map<String, dynamic>.from(jsonDecode(currentAdminJson) as Map),
        );
        _token = savedToken;
      }
    } catch (e) {
      _errorMessage = 'Error loading admin session: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentAdmin != null && _token != null && _token!.isNotEmpty) {
        await prefs.setString(
          'currentAdmin',
          jsonEncode(_currentAdmin!.toJson()),
        );
        await prefs.setString('token', _token!);
      } else {
        await prefs.remove('currentAdmin');
        await prefs.remove('token');
      }
    } catch (e) {
      _errorMessage = 'Error saving admin session: $e';
      notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    _currentAdmin = null;
    _token = null;
    await _saveCurrentAdmin();
  }

  String _extractMessage(http.Response response,
      {String fallback = 'Request failed.'}) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return '$fallback Status: ${response.statusCode}';
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/Auth/login'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Invalid email or password.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final token = data['token']?.toString() ?? '';
      final fullName = data['fullName']?.toString() ?? '';
      final responseEmail = data['email']?.toString() ?? email.trim();
      final role = data['role']?.toString() ?? '';
      final userId = data['userId']?.toString() ?? responseEmail;

      if (token.isEmpty) {
        _errorMessage = 'Login failed: token was not returned.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (role != 'Admin') {
        _errorMessage = 'This account is not authorized for the admin panel.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _token = token;
      _currentAdmin = Admin(
        id: userId,
        email: responseEmail,
        password: '',
        fullName: fullName,
        role: AdminRole.administrator,
        isLoggedIn: true,
      );

      await _saveCurrentAdmin();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
