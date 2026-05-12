import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onlium_mobile/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../models/enrollment.dart';

class EnrollmentProvider extends ChangeNotifier {
  final List<Enrollment> _enrollments = [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  List<Enrollment> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _initialized;

  EnrollmentProvider() {
    _initialized = true;
  }

  // ============================================================
  // MAIN STUDENT ENROLLMENT SUBMIT
  //
  // Backend flow:
  // 1. POST /api/Applications
  // 2. POST /api/Requirements/upload/{applicationId}
  // 3. POST /api/Applications/{applicationId}/submit
  // ============================================================
  Future<bool> submitEnrollment({
    required String userId,
    required StudentType studentType,
    required PersonalInfo personalInfo,
    required List<String> uploadedFiles,
    required String selectedProgram,
    required Schedule preferredSchedule,
    required String profilePicturePath,

    // Add these from your form if available.
    int yearLevel = 1,
    int semester = 1,
    String? gender,
    String? guardianFirstName,
    String? guardianLastName,
    String? guardianRelationship,
    String? guardianContactNumber,
    String? guardianAddress,
  }) async {
    _setLoading();

    try {
      final token = await _requireToken();
      if (token == null) return false;

      final mappedStudentType = _mapStudentType(studentType);

      if ((mappedStudentType == 'NewIncoming' ||
              mappedStudentType == 'Transferee') &&
          !_hasGuardianInfo(
            guardianFirstName,
            guardianLastName,
            guardianRelationship,
            guardianContactNumber,
            guardianAddress,
          )) {
        _setError(
          'Guardian information is required for new/incoming and transferee students.',
        );
        return false;
      }

      final applicationId = await _createApplication(
        token: token,
        studentType: mappedStudentType,
        personalInfo: personalInfo,
        selectedProgram: selectedProgram,
        preferredSchedule: preferredSchedule,
        yearLevel: yearLevel,
        semester: semester,
        gender: gender,
        guardianFirstName: guardianFirstName,
        guardianLastName: guardianLastName,
        guardianRelationship: guardianRelationship,
        guardianContactNumber: guardianContactNumber,
        guardianAddress: guardianAddress,
      );

      if (applicationId == null) return false;

      final filesToUpload = <_RequirementUploadItem>[];

      if (profilePicturePath.trim().isNotEmpty) {
        filesToUpload.add(
          _RequirementUploadItem(
            filePath: profilePicturePath,
            requirementType: 'Profile Picture',
          ),
        );
      }

      for (var i = 0; i < uploadedFiles.length; i++) {
        final path = uploadedFiles[i].trim();

        if (path.isEmpty) continue;

        filesToUpload.add(
          _RequirementUploadItem(
            filePath: path,
            requirementType: 'Requirement ${i + 1}',
          ),
        );
      }

      if (filesToUpload.isEmpty) {
        _setError(
          'Please upload at least one requirement before submitting your application.',
        );
        return false;
      }

      for (final item in filesToUpload) {
        final uploaded = await _uploadRequirement(
          token: token,
          applicationId: applicationId,
          filePath: item.filePath,
          requirementType: item.requirementType,
        );

        if (!uploaded) return false;
      }

      final submitted = await _submitApplication(
        token: token,
        applicationId: applicationId,
      );

      if (!submitted) return false;

      final newEnrollment = Enrollment(
        id: applicationId,
        userId: userId,
        studentType: studentType,
        personalInfo: personalInfo,
        uploadedFiles: uploadedFiles,
        selectedProgram: selectedProgram,
        preferredSchedule: preferredSchedule,
        profilePicturePath: profilePicturePath,
        status: EnrollmentStatus.pending,
      );

      _enrollments.insert(0, newEnrollment);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to submit enrollment: $e');
      return false;
    }
  }

  // ============================================================
  // CONTINUING ENROLLMENT
  //
  // Your backend still requires personal information.
  // So this method now requires real PersonalInfo.
  // ============================================================
  Future<bool> submitContinuingEnrollment({
    required String userId,
    required String year,
    required String program,
    required Schedule preferredSchedule,
    required String clearancePath,
    required PersonalInfo personalInfo,
    int semester = 1,
    String? gender,
  }) async {
    final yearLevel = _parseYearLevel(year);

    return submitEnrollment(
      userId: userId,
      studentType: StudentType.continuing,
      personalInfo: personalInfo,
      uploadedFiles: [clearancePath],
      selectedProgram: program,
      preferredSchedule: preferredSchedule,
      profilePicturePath: '',
      yearLevel: yearLevel,
      semester: semester,
      gender: gender,
    );
  }

  // ============================================================
  // API: CREATE APPLICATION
  // ============================================================
  Future<String?> _createApplication({
    required String token,
    required String studentType,
    required PersonalInfo personalInfo,
    required String selectedProgram,
    required Schedule preferredSchedule,
    required int yearLevel,
    required int semester,
    String? gender,
    String? guardianFirstName,
    String? guardianLastName,
    String? guardianRelationship,
    String? guardianContactNumber,
    String? guardianAddress,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Applications'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'studentType': studentType,
        'programCode': selectedProgram.trim(),
        'yearLevel': yearLevel,
        'semester': semester,
        'preferredSchedule': _mapSchedule(preferredSchedule),

        'firstName': personalInfo.firstName.trim(),
        'lastName': personalInfo.lastName.trim(),
        'phoneNumber': personalInfo.phoneNumber.trim(),
        'address': personalInfo.address.trim(),
        'birthDate': personalInfo.birthDate.toIso8601String(),
        'gender': gender?.trim(),

        'guardianFirstName': guardianFirstName?.trim(),
        'guardianLastName': guardianLastName?.trim(),
        'guardianRelationship': guardianRelationship?.trim(),
        'guardianContactNumber': guardianContactNumber?.trim(),
        'guardianAddress': guardianAddress?.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      _setError(
        _extractMessage(
          response,
          fallback: 'Failed to create enrollment application.',
        ),
      );
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id']?.toString();
  }

  // ============================================================
  // API: UPLOAD REQUIREMENT
  // This matches RequirementsController:
  // - IFormFile file
  // - [FromForm] string requirementType
  // ============================================================
  Future<bool> _uploadRequirement({
    required String token,
    required String applicationId,
    required String filePath,
    required String requirementType,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Requirements/upload/$applicationId',
        ),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['requirementType'] = requirementType;

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        _setError(
          _extractMessage(
            response,
            fallback: 'Failed to upload $requirementType.',
          ),
        );
        return false;
      }

      return true;
    } catch (e) {
      _setError(
        'Failed to upload $requirementType. Make sure the selected file path is valid. Details: $e',
      );
      return false;
    }
  }

  // ============================================================
  // API: SUBMIT APPLICATION TO ADMIN
  // This changes backend status from Draft to PendingReview.
  // ============================================================
  Future<bool> _submitApplication({
    required String token,
    required String applicationId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Applications/$applicationId/submit'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      _setError(
        _extractMessage(
          response,
          fallback: 'Failed to submit application for review.',
        ),
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // OPTIONAL: LOAD APPLICATIONS FROM BACKEND
  // ============================================================
  Future<void> loadEnrollmentData() async {
    _setLoading();

    try {
      final token = await _requireToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Applications/mine'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        _setError(
          _extractMessage(
            response,
            fallback: 'Failed to load enrollment applications.',
          ),
        );
        return;
      }

      // This loads backend applications, but your current Enrollment model
      // may not contain all backend fields. So for now we only clear errors.
      // If you want, send enrollment.dart and I can map backend data into your model.
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Error loading enrollment data: $e');
    }
  }

  // ============================================================
  // LOCAL HELPERS / COMPATIBILITY
  // ============================================================
  List<Enrollment> getEnrollmentsByUserId(String userId) {
    return _enrollments
        .where((enrollment) => enrollment.userId == userId)
        .toList();
  }

  Future<void> updateEnrollmentStatus(
    String enrollmentId,
    EnrollmentStatus newStatus,
  ) async {
    final index = _enrollments.indexWhere((e) => e.id == enrollmentId);

    if (index == -1) return;

    _enrollments[index] = _enrollments[index].copyWith(status: newStatus);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================
  Future<String?> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      _setError('Session expired. Please log in again.');
      return null;
    }

    return token;
  }

  Map<String, String> _authHeaders(String token) {
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Map<String, String> _jsonHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _extractMessage(http.Response response, {required String fallback}) {
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

  void _setLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();

    if (kDebugMode) {
      print('EnrollmentProvider error: $message');
    }
  }

  String _mapStudentType(StudentType type) {
    switch (type) {
      case StudentType.newIncoming:
        return 'NewIncoming';
      case StudentType.transferee:
        return 'Transferee';
      case StudentType.continuing:
        return 'Continuing';
    }
  }

  String _mapSchedule(Schedule schedule) {
    switch (schedule) {
      case Schedule.morning:
        return 'Morning';
      case Schedule.afternoon:
        return 'Afternoon';
      case Schedule.evening:
        return 'Evening';
    }
  }

  int _parseYearLevel(String year) {
    final normalized = year.toLowerCase().trim();

    if (normalized.contains('1')) return 1;
    if (normalized.contains('2')) return 2;
    if (normalized.contains('3')) return 3;
    if (normalized.contains('4')) return 4;

    return int.tryParse(year) ?? 1;
  }

  bool _hasGuardianInfo(
    String? guardianFirstName,
    String? guardianLastName,
    String? guardianRelationship,
    String? guardianContactNumber,
    String? guardianAddress,
  ) {
    return guardianFirstName != null &&
        guardianFirstName.trim().isNotEmpty &&
        guardianLastName != null &&
        guardianLastName.trim().isNotEmpty &&
        guardianRelationship != null &&
        guardianRelationship.trim().isNotEmpty &&
        guardianContactNumber != null &&
        guardianContactNumber.trim().isNotEmpty &&
        guardianAddress != null &&
        guardianAddress.trim().isNotEmpty;
  }
}

class _RequirementUploadItem {
  final String filePath;
  final String requirementType;

  const _RequirementUploadItem({
    required this.filePath,
    required this.requirementType,
  });
}
