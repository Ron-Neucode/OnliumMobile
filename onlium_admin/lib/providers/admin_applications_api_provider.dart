import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminApplicationsApiProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';
  // Android emulator:
  // static const String _baseUrl = 'http://10.0.2.2:5027';
  // Windows desktop:
  // static const String _baseUrl = 'https://localhost:7164';

  final List<Map<String, dynamic>> _pendingEnrollments = [];
  final List<Map<String, dynamic>> _approvedEnrollments = [];
  final List<Map<String, dynamic>> _rejectedEnrollments = [];
  Future<List<Map<String, dynamic>>> fetchCompletedStudents({
    int? yearLevel,
    String? programCode,
    String? gender,
    String? studentType,
  }) async {
    final token = await _requireToken();
    if (token == null) {
      throw Exception(_errorMessage);
    }

    final queryParams = <String, String>{};

    if (yearLevel != null) {
      queryParams['yearLevel'] = yearLevel.toString();
    }
    if (programCode != null && programCode.isNotEmpty) {
      queryParams['programCode'] = programCode;
    }
    if (gender != null && gender.isNotEmpty) {
      queryParams['gender'] = gender;
    }
    if (studentType != null && studentType.isNotEmpty) {
      queryParams['studentType'] = studentType;
    }

    final uri = Uri.parse(
      '$_baseUrl/api/admin/students',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(
      uri,
      headers: _authHeaders(token),
    );

    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw Exception(_errorMessage);
    }

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(
          response,
          fallback: 'Failed to load students.',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

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

  String _extractMessage(http.Response response,
      {String fallback = 'Request failed.'}) {
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

  Future<List<Map<String, dynamic>>> _fetchByStatus(String status) async {
    final token = await _requireToken();
    if (token == null) {
      throw Exception(_errorMessage);
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/applications?status=$status'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw Exception(_errorMessage);
    }

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(
          response,
          fallback: 'Failed to load $status applications.',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> fetchPendingEnrollments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pending = await _fetchByStatus('PendingReview');
      _pendingEnrollments
        ..clear()
        ..addAll(pending);
    } catch (e) {
      _errorMessage = 'Error loading enrollments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllEnrollments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pending = await _fetchByStatus('PendingReview');
      final approved = await _fetchByStatus('Approved');
      final rejected = await _fetchByStatus('Rejected');

      _pendingEnrollments
        ..clear()
        ..addAll(pending);

      _approvedEnrollments
        ..clear()
        ..addAll(approved);

      _rejectedEnrollments
        ..clear()
        ..addAll(rejected);
    } catch (e) {
      _errorMessage = 'Error loading enrollments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveEnrollment(String enrollmentId) async {
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
        Uri.parse('$_baseUrl/api/admin/applications/$enrollmentId/approve'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to approve application.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await fetchAllEnrollments();
      return true;
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
      final token = await _requireToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/applications/$enrollmentId/reject'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to reject application.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await fetchAllEnrollments();
      return true;
    } catch (e) {
      _errorMessage = 'Error rejecting enrollment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAppointment({
    required String applicationId,
    required DateTime appointmentDate,
    String? location,
    String? notes,
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
        Uri.parse('$_baseUrl/api/admin/appointments'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({
          'applicationId': applicationId,
          'appointmentDate': appointmentDate.toIso8601String(),
          'location': location?.trim(),
          'notes': notes?.trim(),
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
          fallback: 'Failed to create appointment.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error creating appointment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    final token = await _requireToken();
    if (token == null) {
      throw Exception(_errorMessage);
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/appointments'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw Exception(_errorMessage);
    }

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(
          response,
          fallback: 'Failed to load appointments.',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<bool> confirmPayment(String appointmentId) async {
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

      final response = await http.put(
        Uri.parse(
            '$_baseUrl/api/admin/appointments/$appointmentId/confirm-payment'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to confirm payment.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error confirming payment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeEnrollment(String appointmentId) async {
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

      final response = await http.put(
        Uri.parse('$_baseUrl/api/admin/appointments/$appointmentId/complete'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to complete enrollment.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error completing enrollment: $e';
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
