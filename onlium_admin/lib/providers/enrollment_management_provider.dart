import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnrollmentManagementProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';

  final List<Map<String, dynamic>> _pendingEnrollments = [];
  final List<Map<String, dynamic>> _approvedEnrollments = [];
  final List<Map<String, dynamic>> _rejectedEnrollments = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get pendingEnrollments => _pendingEnrollments;
  List<Map<String, dynamic>> get approvedEnrollments => _approvedEnrollments;
  List<Map<String, dynamic>> get rejectedEnrollments => _rejectedEnrollments;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _pendingEnrollments.length;
  int get approvedCount => _approvedEnrollments.length;
  int get rejectedCount => _rejectedEnrollments.length;

  EnrollmentManagementProvider() {
    fetchPendingEnrollments();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchPendingEnrollments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _errorMessage = 'Admin token not found. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/applications'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;

        _pendingEnrollments
          ..clear()
          ..addAll(
            decoded.map((e) => Map<String, dynamic>.from(e as Map)),
          );

        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage =
            'Failed to load enrollments. Status: ${response.statusCode}';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading enrollments: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveEnrollment(String enrollmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _errorMessage = 'Admin token not found. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/applications/$enrollmentId/approve'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final index =
            _pendingEnrollments.indexWhere((e) => e['id'] == enrollmentId);

        if (index != -1) {
          final item = Map<String, dynamic>.from(_pendingEnrollments[index]);
          item['status'] = 'Approved';
          item['reviewedAt'] = DateTime.now().toIso8601String();
          item['adminReviewComment'] = null;

          _pendingEnrollments.removeAt(index);
          _approvedEnrollments.insert(0, item);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _errorMessage =
              data['message']?.toString() ?? 'Failed to approve application.';
        } catch (_) {
          _errorMessage =
              'Failed to approve application. Status: ${response.statusCode}';
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error approving enrollment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectEnrollment(String enrollmentId, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _errorMessage = 'Admin token not found. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/applications/$enrollmentId/reject'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final index =
            _pendingEnrollments.indexWhere((e) => e['id'] == enrollmentId);

        if (index != -1) {
          final item = Map<String, dynamic>.from(_pendingEnrollments[index]);
          item['status'] = 'Rejected';
          item['reviewedAt'] = DateTime.now().toIso8601String();
          item['adminReviewComment'] = reason;

          _pendingEnrollments.removeAt(index);
          _rejectedEnrollments.insert(0, item);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _errorMessage =
              data['message']?.toString() ?? 'Failed to reject application.';
        } catch (_) {
          _errorMessage =
              'Failed to reject application. Status: ${response.statusCode}';
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error rejecting enrollment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> getEnrollmentsByStatus(String status) {
    switch (status) {
      case 'PendingReview':
        return _pendingEnrollments;
      case 'Approved':
        return _approvedEnrollments;
      case 'Rejected':
        return _rejectedEnrollments;
      default:
        return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
