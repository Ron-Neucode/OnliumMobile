import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminResourcesApiProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';

  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _resources = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get resources => _resources;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _clearAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('currentAdmin');
  }

  Map<String, String> _authHeaders(String token, {bool json = false}) {
    return {
      'Accept': '*/*',
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  String _extractMessage(
    http.Response response, {
    String fallback = 'Request failed.',
  }) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return '$fallback Status: ${response.statusCode}';
    }
  }

  Future<String?> _requireToken() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _errorMessage = 'Admin token not found. Please log in again.';
      return null;
    }
    return token;
  }

  Future<void> _handleUnauthorized() async {
    await _clearAdminSession();
    _errorMessage = 'Session expired. Please log in again.';
  }

  Future<void> fetchResources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _requireToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/resources'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to load resources.',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;

      _resources =
          decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading resources: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createResource({
    required String resourceType,
    required String title,
    required String url,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _requireToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/resources'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({
          'resourceType': resourceType,
          'title': title.trim(),
          'url': url.trim(),
        }),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to create resource.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await fetchResources();
      return true;
    } catch (e) {
      _errorMessage = 'Error creating resource: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
