import 'package:onlium_admin/models/shared.dart';

class EnrollmentRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final StudentType studentType;
  final String program;
  final EnrollmentStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;

  EnrollmentRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentType,
    required this.program,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
  });

  EnrollmentRequest copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    StudentType? studentType,
    String? program,
    EnrollmentStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
  }) {
    return EnrollmentRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      studentType: studentType ?? this.studentType,
      program: program ?? this.program,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentType': studentType.toString(),
      'program': program,
      'status': status.toString(),
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
    };
  }

  factory EnrollmentRequest.fromJson(Map<String, dynamic> json) {
    return EnrollmentRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentEmail: json['studentEmail'] as String,
      studentType: StudentType.values.firstWhere(
        (e) => e.toString() == json['studentType'],
        orElse: () => StudentType.newIncoming,
      ),
      program: json['program'] as String,
      status: EnrollmentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EnrollmentStatus.pending,
      ),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedBy: json['reviewedBy'] as String?,
      reviewNotes: json['reviewNotes'] as String?,
    );
  }
}
