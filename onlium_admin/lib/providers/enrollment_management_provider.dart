import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enrollment_request.dart';
import '../models/shared.dart';

class EnrollmentManagementProvider extends ChangeNotifier {
  List<EnrollmentRequest> _enrollmentRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EnrollmentRequest> get enrollmentRequests => _enrollmentRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _enrollmentRequests
      .where((e) => e.status == EnrollmentStatus.pending)
      .length;
  int get approvedCount => _enrollmentRequests
      .where((e) => e.status == EnrollmentStatus.approved)
      .length;
  int get rejectedCount => _enrollmentRequests
      .where((e) => e.status == EnrollmentStatus.rejected)
      .length;

  EnrollmentManagementProvider() {
    _loadEnrollmentRequests();
  }

  Future<void> _loadEnrollmentRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList('enrollmentRequests') ?? [];
      _enrollmentRequests = requestsJson
          .map(
            (jsonString) => EnrollmentRequest.fromJson(
              Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading enrollment requests: $e';
      notifyListeners();
    }
  }

  Future<void> _saveEnrollmentRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = _enrollmentRequests
          .map((req) => jsonEncode(req.toJson()))
          .toList();
      await prefs.setStringList('enrollmentRequests', requestsJson);
    } catch (e) {
      _errorMessage = 'Error saving enrollment requests: $e';
      notifyListeners();
    }
  }

  Future<void> approveEnrollment(
    String enrollmentId,
    String adminId,
    String? notes,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final index = _enrollmentRequests.indexWhere((e) => e.id == enrollmentId);
      if (index != -1) {
        _enrollmentRequests[index] = _enrollmentRequests[index].copyWith(
          status: EnrollmentStatus.approved,
          reviewedAt: DateTime.now(),
          reviewedBy: adminId,
          reviewNotes: notes,
        );
        await _saveEnrollmentRequests();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error approving enrollment: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectEnrollment(
    String enrollmentId,
    String adminId,
    String reason,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final index = _enrollmentRequests.indexWhere((e) => e.id == enrollmentId);
      if (index != -1) {
        _enrollmentRequests[index] = _enrollmentRequests[index].copyWith(
          status: EnrollmentStatus.rejected,
          reviewedAt: DateTime.now(),
          reviewedBy: adminId,
          reviewNotes: reason,
        );
        await _saveEnrollmentRequests();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error rejecting enrollment: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  List<EnrollmentRequest> getEnrollmentsByStatus(EnrollmentStatus status) {
    return _enrollmentRequests
        .where((enrollment) => enrollment.status == status)
        .toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
