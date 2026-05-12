import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminStudyLoadScheduleProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';

  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _pendingSchedules = [];
  final List<Map<String, dynamic>> _approvedSchedules = [];
  final List<Map<String, dynamic>> _rejectedSchedules = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get pendingSchedules => _pendingSchedules;
  List<Map<String, dynamic>> get approvedSchedules => _approvedSchedules;
  List<Map<String, dynamic>> get rejectedSchedules => _rejectedSchedules;

  int get pendingCount => _pendingSchedules.length;
  int get approvedCount => _approvedSchedules.length;
  int get rejectedCount => _rejectedSchedules.length;

  List<Map<String, dynamic>> getSchedulesByStatus(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'pendingreview':
        return _pendingSchedules;
      case 'approved':
        return _approvedSchedules;
      case 'rejected':
        return _rejectedSchedules;
      default:
        return [];
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _jsonAuthHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _extractMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? fallback;
      }

      return fallback;
    } catch (_) {
      return '$fallback Status: ${response.statusCode}';
    }
  }

  Future<void> fetchAllSchedules() async {
    _isLoading = true;
    _errorMessage = null;

    _pendingSchedules.clear();
    _approvedSchedules.clear();
    _rejectedSchedules.clear();

    notifyListeners();

    try {
      final pending = await _fetchByStatus('PendingReview');
      final approved = await _fetchByStatus('Approved');
      final rejected = await _fetchByStatus('Rejected');

      _pendingSchedules
        ..clear()
        ..addAll(pending);

      _approvedSchedules
        ..clear()
        ..addAll(approved);

      _rejectedSchedules
        ..clear()
        ..addAll(rejected);
    } catch (e) {
      _errorMessage = 'Error loading study load schedules: $e';

      if (kDebugMode) {
        print(_errorMessage);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchByStatus(String status) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Admin token not found. Please log in again.');
    }

    final uri = Uri.parse(
      '$_baseUrl/api/admin/study-load-schedules',
    ).replace(
      queryParameters: {
        'status': status,
      },
    );

    final response = await http.get(
      uri,
      headers: _authHeaders(token),
    );

    if (kDebugMode) {
      print('ADMIN STUDY LOAD SCHEDULE REQUEST: $uri');
      print('STATUS CODE: ${response.statusCode}');
      print('BODY: ${response.body}');
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'This account is not authorized to view study load schedule submissions.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(
          response,
          'Failed to load $status study load schedules.',
        ),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid server response. Expected a list.');
    }

    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> fetchScheduleDetails(String id) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Admin token not found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/study-load-schedules/$id'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(response, 'Failed to load schedule details.'),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid server response. Expected object.');
    }

    return decoded;
  }

  Future<bool> approveSchedule(String id) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      _errorMessage = 'Admin token not found. Please log in again.';
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/study-load-schedules/$id/approve'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          'Failed to approve study load schedule.',
        );
        notifyListeners();
        return false;
      }

      await fetchAllSchedules();
      return true;
    } catch (e) {
      _errorMessage = 'Error approving schedule: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectSchedule({
    required String id,
    required String comment,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      _errorMessage = 'Admin token not found. Please log in again.';
      notifyListeners();
      return false;
    }

    if (comment.trim().isEmpty) {
      _errorMessage = 'Rejection comment is required.';
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/study-load-schedules/$id/reject'),
        headers: _jsonAuthHeaders(token),
        body: jsonEncode({
          'comment': comment.trim(),
        }),
      );

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          'Failed to reject study load schedule.',
        );
        notifyListeners();
        return false;
      }

      await fetchAllSchedules();
      return true;
    } catch (e) {
      _errorMessage = 'Error rejecting schedule: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
