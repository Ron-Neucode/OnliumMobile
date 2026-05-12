import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class StudentResourcesProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isForbidden = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _resources = [];

  bool get isLoading => _isLoading;
  bool get isForbidden => _isForbidden;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get resources => _resources;

  Map<String, dynamic>? get examResource {
    return _getResourceByType('exam');
  }

  Map<String, dynamic>? get quizResource {
    return _getResourceByType('quiz');
  }

  Future<void> fetchResources() async {
    _isLoading = true;
    _isForbidden = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _resources = [];
        _errorMessage = 'Your session has expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Resources'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        _resources = List<Map<String, dynamic>>.from(decoded);
        _isForbidden = false;
        _errorMessage = null;
      } else if (response.statusCode == 403) {
        final decoded = _tryDecodeObject(response.body);

        _resources = [];
        _isForbidden = true;
        _errorMessage =
            decoded['message']?.toString() ??
            'LMS resources are not available for your enrolled course.';
      } else if (response.statusCode == 401) {
        _resources = [];
        _errorMessage = 'Your session has expired. Please log in again.';
      } else {
        final decoded = _tryDecodeObject(response.body);

        _resources = [];
        _errorMessage =
            decoded['message']?.toString() ??
            'Failed to load LMS resources. Status: ${response.statusCode}.';
      }
    } catch (e) {
      _resources = [];
      _errorMessage = 'Failed to connect to the server: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchResources();
  }

  Map<String, dynamic>? _getResourceByType(String type) {
    final matches = _resources.where((resource) {
      final resourceType = resource['resourceType']?.toString().toLowerCase();
      return resourceType == type || resourceType == 'lms $type';
    }).toList();

    if (matches.isEmpty) {
      return null;
    }

    return matches.first;
  }

  Map<String, dynamic> _tryDecodeObject(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      return {};
    }
  }
}
