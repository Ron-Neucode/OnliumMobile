import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';

  String? _token;
  String? _email;
  String? _fullName;
  String? _role;

  String? _firstName;
  String? _lastName;
  String? _phoneNumber;
  String? _address;
  DateTime? _birthDate;

  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  String? get token => _token;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get role => _role;

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get phoneNumber => _phoneNumber;
  String? get address => _address;
  DateTime? get birthDate => _birthDate;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  AuthProvider() {
    loadAuthData();
  }

  Future<void> loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _token = prefs.getString('token');
      _email = prefs.getString('email');
      _fullName = prefs.getString('fullName');
      _role = prefs.getString('role');

      _firstName = prefs.getString('firstName');
      _lastName = prefs.getString('lastName');
      _phoneNumber = prefs.getString('phoneNumber');
      _address = prefs.getString('address');

      final birthDateString = prefs.getString('birthDate');
      _birthDate = birthDateString != null && birthDateString.isNotEmpty
          ? DateTime.tryParse(birthDateString)
          : null;

      _initialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading auth data: $e';
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveSession({
    required String token,
    required String email,
    required String fullName,
    required String role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    DateTime? birthDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setString('role', role);

    if (firstName != null) {
      await prefs.setString('firstName', firstName);
    }
    if (lastName != null) {
      await prefs.setString('lastName', lastName);
    }
    if (phoneNumber != null) {
      await prefs.setString('phoneNumber', phoneNumber);
    }
    if (address != null) {
      await prefs.setString('address', address);
    }
    if (birthDate != null) {
      await prefs.setString('birthDate', birthDate.toIso8601String());
    }

    _token = token;
    _email = email;
    _fullName = fullName;
    _role = role;
    _firstName = firstName ?? _firstName;
    _lastName = lastName ?? _lastName;
    _phoneNumber = phoneNumber ?? _phoneNumber;
    _address = address ?? _address;
    _birthDate = birthDate ?? _birthDate;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('fullName');
    await prefs.remove('role');
    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('phoneNumber');
    await prefs.remove('address');
    await prefs.remove('birthDate');

    _token = null;
    _email = null;
    _fullName = null;
    _role = null;
    _firstName = null;
    _lastName = null;
    _phoneNumber = null;
    _address = null;
    _birthDate = null;
  }

  Future<bool> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/Auth/register');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = data['message']?.toString() ?? 'Registration failed.';
      } catch (_) {
        _errorMessage = 'Registration failed. Status: ${response.statusCode}';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/Auth/login');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        body: jsonEncode({'email': email.trim(), 'password': password.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final token = data['token']?.toString() ?? '';
        final fullName = data['fullName']?.toString() ?? '';
        final responseEmail = data['email']?.toString() ?? '';
        final role = data['role']?.toString() ?? '';

        await _saveSession(
          token: token,
          email: responseEmail,
          fullName: fullName,
          role: role,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage =
            data['message']?.toString() ?? 'Invalid email or password.';
      } catch (_) {
        _errorMessage = 'Login failed. Status: ${response.statusCode}';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    required DateTime birthDate,
  }) async {
    if (_token == null || _token!.isEmpty) {
      _errorMessage = 'You are not logged in.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/StudentProfiles/me');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'phoneNumber': phoneNumber.trim(),
          'address': address.trim(),
          'birthDate': birthDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final newFullName = '${firstName.trim()} ${lastName.trim()}'.trim();

        await _saveSession(
          token: _token!,
          email: _email ?? '',
          fullName: newFullName,
          role: _role ?? '',
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          phoneNumber: phoneNumber.trim(),
          address: address.trim(),
          birthDate: birthDate,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (response.statusCode == 401) {
        await logout();
        _errorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return false;
      }

      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = data['message']?.toString() ?? 'Profile update failed.';
      } catch (_) {
        _errorMessage = 'Profile update failed. Status: ${response.statusCode}';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Profile update failed: $e';
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
