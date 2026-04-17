import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  User? get currentUser => _currentUser;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isLoggedIn;
  bool get isInitialized => _initialized;

  AuthProvider() {
    _initialized = true;
    if (kDebugMode) {
      print('AuthProvider initialized');
    }
  }

  Future<void> loadAuthData() async {
    try {
      await _loadUsers();
      await _loadCurrentUser();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading auth data: $e';
      if (kDebugMode) {
        print('AuthProvider.loadAuthData error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];
      _users = usersJson.map((jsonString) {
        try {
          return User.fromJson(
            Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing user: $e');
          }
          rethrow;
        }
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading users: $e';
      if (kDebugMode) {
        print('AuthProvider._loadUsers error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = _users
          .map((user) => jsonEncode(user.toJson()))
          .toList();
      await prefs.setStringList('users', usersJson);
    } catch (e) {
      _errorMessage = 'Error saving users: $e';
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('currentUser');
      if (currentUserJson != null) {
        try {
          _currentUser = User.fromJson(
            Map<String, dynamic>.from(jsonDecode(currentUserJson) as Map),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing current user: $e');
          }
          rethrow;
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading current user: $e';
      if (kDebugMode) {
        print('AuthProvider._loadCurrentUser error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _saveCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setString(
          'currentUser',
          jsonEncode(_currentUser!.toJson()),
        );
      } else {
        await prefs.remove('currentUser');
      }
    } catch (e) {
      _errorMessage = 'Error saving current user: $e';
      notifyListeners();
    }
  }

  Future<void> updateCurrentUser(User updatedUser) async {
    _currentUser = updatedUser.copyWith(isLoggedIn: true);

    final index = _users.indexWhere((user) => user.id == updatedUser.id);
    if (index >= 0) {
      _users[index] = updatedUser;
      await _saveUsers();
    }

    await _saveCurrentUser();
    notifyListeners();
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    StudentType studentType,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if email already exists
      if (_users.any((user) => user.email == email)) {
        _errorMessage = 'Email already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName,
        email: email,
        password: password,
        studentType: studentType,
      );

      _users.add(newUser);
      await _saveUsers();

      _isLoading = false;
      notifyListeners();
      return true;
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
      final user = _users.firstWhere(
        (u) => u.email == email && u.password == password,
        orElse: () => throw Exception('Invalid credentials'),
      );

      _currentUser = user.copyWith(isLoggedIn: true);
      await _saveCurrentUser();

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
    _currentUser = null;
    await _saveCurrentUser();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
