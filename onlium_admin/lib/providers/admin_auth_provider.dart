import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin.dart';

class AdminAuthProvider extends ChangeNotifier {
  Admin? _currentAdmin;
  List<Admin> _admins = [];
  bool _isLoading = false;
  String? _errorMessage;

  Admin? get currentAdmin => _currentAdmin;
  List<Admin> get admins => _admins;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _currentAdmin != null && _currentAdmin!.isLoggedIn;

  AdminAuthProvider() {
    _initializeDefaultAdmins();
    _loadCurrentAdmin();
  }

  void _initializeDefaultAdmins() {
    _admins = [
      Admin(
        id: '1',
        email: 'admin@edu.com',
        password: 'admin123',
        fullName: 'Administrator',
        role: AdminRole.administrator,
      ),
    ];
    _saveAdmins();
  }

  Future<void> _loadCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentAdminJson = prefs.getString('currentAdmin');
      if (currentAdminJson != null) {
        _currentAdmin = Admin.fromJson(
          Map<String, dynamic>.from(jsonDecode(currentAdminJson) as Map),
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error loading admin session: $e';
      notifyListeners();
    }
  }

  Future<void> _saveCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentAdmin != null) {
        await prefs.setString(
          'currentAdmin',
          jsonEncode(_currentAdmin!.toJson()),
        );
      } else {
        await prefs.remove('currentAdmin');
      }
    } catch (e) {
      _errorMessage = 'Error saving admin session: $e';
      notifyListeners();
    }
  }

  Future<void> _saveAdmins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminsJson = _admins
          .map((admin) => jsonEncode(admin.toJson()))
          .toList();
      await prefs.setStringList('admins', adminsJson);
    } catch (e) {
      _errorMessage = 'Error saving admins: $e';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final admin = _admins.firstWhere(
        (a) => a.email == email && a.password == password,
        orElse: () => throw Exception('Invalid credentials'),
      );

      _currentAdmin = admin.copyWith(isLoggedIn: true);
      await _saveCurrentAdmin();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: Invalid email or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentAdmin = null;
    await _saveCurrentAdmin();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
