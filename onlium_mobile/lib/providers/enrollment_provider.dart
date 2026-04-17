import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onlium_mobile/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/enrollment.dart';

class EnrollmentProvider extends ChangeNotifier {
  List<Enrollment> _enrollments = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  List<Enrollment> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _initialized;

  EnrollmentProvider() {
    _initialized = true;
    if (kDebugMode) {
      print('EnrollmentProvider initialized');
    }
  }

  Future<void> loadEnrollmentData() async {
    try {
      await _loadEnrollments();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading enrollment data: $e';
      if (kDebugMode) {
        print('EnrollmentProvider.loadEnrollmentData error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _loadEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enrollmentsJson = prefs.getStringList('enrollments') ?? [];
      _enrollments = enrollmentsJson.map((jsonString) {
        try {
          return Enrollment.fromJson(
            Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing enrollment: $e');
          }
          rethrow;
        }
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading enrollments: $e';
      if (kDebugMode) {
        print('EnrollmentProvider._loadEnrollments error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> _saveEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enrollmentsJson = _enrollments
          .map((enrollment) => jsonEncode(enrollment.toJson()))
          .toList();
      await prefs.setStringList('enrollments', enrollmentsJson);
    } catch (e) {
      _errorMessage = 'Error saving enrollments: $e';
      notifyListeners();
    }
  }

  Future<bool> submitEnrollment({
    required String userId,
    required StudentType studentType,
    required PersonalInfo personalInfo,
    required List<String> uploadedFiles,
    required String selectedProgram,
    required Schedule preferredSchedule,
    required String profilePicturePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newEnrollment = Enrollment(
        id: const Uuid().v4(),
        userId: userId,
        studentType: studentType,
        personalInfo: personalInfo,
        uploadedFiles: uploadedFiles,
        selectedProgram: selectedProgram,
        preferredSchedule: preferredSchedule,
        profilePicturePath: profilePicturePath,
        status: EnrollmentStatus.pending,
      );

      _enrollments.add(newEnrollment);
      await _saveEnrollments();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit enrollment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitContinuingEnrollment({
    required String userId,
    required String year,
    required String program,
    required Schedule preferredSchedule,
    required String clearancePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final personalInfo = PersonalInfo(
        firstName: 'John', // This would come from user profile
        lastName: 'Doe',
        middleName: 'Smith',
        phoneNumber: '123-456-7890',
        address: '123 Main St, City',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      );

      final newEnrollment = Enrollment(
        id: const Uuid().v4(),
        userId: userId,
        studentType: StudentType.continuing,
        personalInfo: personalInfo,
        uploadedFiles: [clearancePath],
        selectedProgram: program,
        preferredSchedule: preferredSchedule,
        status: EnrollmentStatus.pending,
      );

      _enrollments.add(newEnrollment);
      await _saveEnrollments();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit enrollment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Enrollment> getEnrollmentsByUserId(String userId) {
    return _enrollments
        .where((enrollment) => enrollment.userId == userId)
        .toList();
  }

  Future<void> updateEnrollmentStatus(
    String enrollmentId,
    EnrollmentStatus newStatus,
  ) async {
    try {
      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index != -1) {
        _enrollments[index] = _enrollments[index].copyWith(status: newStatus);
        await _saveEnrollments();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error updating enrollment status: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
