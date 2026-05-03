import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminStudyLoadsApiProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _studyLoads = [];

  // Filter persistence
  String? _selectedProgram;
  int? _selectedYear;
  int? _selectedSemester;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get studyLoads => _studyLoads;

  String? get selectedProgram => _selectedProgram;
  int? get selectedYear => _selectedYear;
  int? get selectedSemester => _selectedSemester;

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

  Future<void> fetchStudyLoads({
    String? programCode,
    int? yearLevel,
    int? semester,
  }) async {
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

      final query = <String, String>{};
      if (programCode != null && programCode.isNotEmpty) {
        query['programCode'] = programCode;
      }
      if (yearLevel != null) {
        query['yearLevel'] = yearLevel.toString();
      }
      if (semester != null) {
        query['semester'] = semester.toString();
      }

      final uri = Uri.parse('$_baseUrl/api/StudyLoads').replace(
        queryParameters: query.isEmpty ? null : query,
      );

      final response = await http.get(
        uri,
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
          fallback: 'Failed to load study loads.',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      _studyLoads =
          decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Store filter values
      _selectedProgram = programCode;
      _selectedYear = yearLevel;
      _selectedSemester = semester;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading study loads: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStudyLoad({
    required String programCode,
    required int yearLevel,
    required int semester,
    required String subjectCode,
    required String subjectTitle,
    required double lecUnits,
    required double labUnits,
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
        Uri.parse('$_baseUrl/api/StudyLoads'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({
          'programCode': programCode.trim(),
          'yearLevel': yearLevel,
          'semester': semester,
          'subjectCode': subjectCode.trim(),
          'subjectTitle': subjectTitle.trim(),
          'lecUnits': lecUnits,
          'labUnits': labUnits,
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
          fallback: 'Failed to create study load.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await fetchStudyLoads(
        programCode: programCode,
        yearLevel: yearLevel,
        semester: semester,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Error creating study load: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudyLoad({
    required int id,
    required String programCode,
    required int yearLevel,
    required int semester,
    required String subjectCode,
    required String subjectTitle,
    required double lecUnits,
    required double labUnits,
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

      final response = await http.put(
        Uri.parse('$_baseUrl/api/StudyLoads/$id'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({
          'id': id,
          'programCode': programCode.trim(),
          'yearLevel': yearLevel,
          'semester': semester,
          'subjectCode': subjectCode.trim(),
          'subjectTitle': subjectTitle.trim(),
          'lecUnits': lecUnits,
          'labUnits': labUnits,
        }),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to update study load.',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Refresh with current filters
      await fetchStudyLoads(
        programCode: _selectedProgram,
        yearLevel: _selectedYear,
        semester: _selectedSemester,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Error updating study load: $e';
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
