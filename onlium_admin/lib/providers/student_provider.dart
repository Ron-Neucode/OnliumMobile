import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

class StudentProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://localhost:7164';

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedGender;
  String? _selectedYear;
  String? _selectedCourse;
  String? _selectedType;

  // Getters
  List<Student> get students => _filteredStudents.isEmpty ? _students : _filteredStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedGender => _selectedGender;
  String? get selectedYear => _selectedYear;
  String? get selectedCourse => _selectedCourse;
  String? get selectedType => _selectedType;

  // Filters
  void setGenderFilter(String? gender) {
    _selectedGender = gender == 'All' ? null : gender;
    _applyFilters();
    notifyListeners();
  }

  void setYearFilter(String? year) {
    _selectedYear = year == 'All' ? null : year;
    _applyFilters();
    notifyListeners();
  }

  void setCourseFilter(String? course) {
    _selectedCourse = course == 'All' ? null : course;
    _applyFilters();
    notifyListeners();
  }

  void setTypeFilter(String? type) {
    _selectedType = type == 'All' ? null : type;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedGender = null;
    _selectedYear = null;
    _selectedCourse = null;
    _selectedType = null;
    _filteredStudents = [];
    notifyListeners();
  }

  void _applyFilters() {
    _filteredStudents = _students.where((student) {
      bool matchesGender = _selectedGender == null || 
                          student.gender.toLowerCase() == _selectedGender!.toLowerCase();
      bool matchesYear = _selectedYear == null || 
                        student.yearLevel.toLowerCase().contains(_selectedYear!.toLowerCase());
      bool matchesCourse = _selectedCourse == null || 
                          student.program.toLowerCase().contains(_selectedCourse!.toLowerCase());
      bool matchesType = _selectedType == null || 
                        student.studentType.toLowerCase().contains(_selectedType!.toLowerCase());
      
      return matchesGender && matchesYear && matchesCourse && matchesType;
    }).toList();
  }

  // API Methods
  Future<void> fetchStudents({
    String? gender,
    String? yearLevel,
    String? program,
    String? studentType,
  }) async {
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

      // Build query parameters
      final queryParams = <String, String>{};
      if (gender != null && gender.isNotEmpty && gender != 'All') {
        queryParams['gender'] = gender;
      }
      if (yearLevel != null && yearLevel.isNotEmpty && yearLevel != 'All') {
        // Extract number from "1st Year", "2nd Year", etc.
        final yearMatch = RegExp(r'(\d+)').firstMatch(yearLevel);
        if (yearMatch != null) {
          queryParams['yearLevel'] = yearMatch.group(1)!;
        }
      }
      if (program != null && program.isNotEmpty && program != 'All') {
        queryParams['programCode'] = program;
      }
      if (studentType != null && studentType.isNotEmpty && studentType != 'All') {
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
        await _clearSession();
        _errorMessage = 'Session expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (response.statusCode != 200) {
        _errorMessage = _extractMessage(
          response,
          fallback: 'Failed to load students.',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      _students = decoded
          .map((e) => Student.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching students: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Student?> getStudentById(String studentId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Admin token not found.';
        notifyListeners();
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/students/$studentId'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        return Student.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
      }

      if (response.statusCode == 401) {
        await _clearSession();
        _errorMessage = 'Session expired.';
        notifyListeners();
        return null;
      }

      return null;
    } catch (e) {
      _errorMessage = 'Error fetching student: $e';
      notifyListeners();
      return null;
    }
  }

  // Helper methods
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('currentAdmin');
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Accept': '*/*',
      'Authorization': 'Bearer $token',
    };
  }

  String _extractMessage(http.Response response, {String fallback = 'Request failed.'}) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return '$fallback Status: ${response.statusCode}';
    }
  }
}
