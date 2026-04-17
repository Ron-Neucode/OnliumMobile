import 'user.dart';
export 'user.dart';

class Enrollment {
  final String id;
  final String userId;
  final StudentType studentType;
  final PersonalInfo personalInfo;
  final List<String> uploadedFiles;
  final String? selectedProgram;
  final Schedule preferredSchedule;
  final String? profilePicturePath;
  final EnrollmentStatus status;
  final DateTime createdAt;

  Enrollment({
    required this.id,
    required this.userId,
    required this.studentType,
    required this.personalInfo,
    this.uploadedFiles = const [],
    this.selectedProgram,
    this.preferredSchedule = Schedule.morning,
    this.profilePicturePath,
    this.status = EnrollmentStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Enrollment copyWith({
    String? id,
    String? userId,
    StudentType? studentType,
    PersonalInfo? personalInfo,
    List<String>? uploadedFiles,
    String? selectedProgram,
    Schedule? preferredSchedule,
    String? profilePicturePath,
    EnrollmentStatus? status,
    DateTime? createdAt,
  }) {
    return Enrollment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentType: studentType ?? this.studentType,
      personalInfo: personalInfo ?? this.personalInfo,
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
      selectedProgram: selectedProgram ?? this.selectedProgram,
      preferredSchedule: preferredSchedule ?? this.preferredSchedule,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'studentType': studentType.toString(),
      'personalInfo': personalInfo.toJson(),
      'uploadedFiles': uploadedFiles,
      'selectedProgram': selectedProgram,
      'preferredSchedule': preferredSchedule.toString(),
      'profilePicturePath': profilePicturePath,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      studentType: StudentType.values.firstWhere(
        (e) => e.toString() == json['studentType'],
        orElse: () => StudentType.newIncoming,
      ),
      personalInfo: PersonalInfo.fromJson(
        Map<String, dynamic>.from(json['personalInfo'] as Map),
      ),
      uploadedFiles:
          (json['uploadedFiles'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedProgram: json['selectedProgram'] as String?,
      preferredSchedule: Schedule.values.firstWhere(
        (e) => e.toString() == json['preferredSchedule'],
        orElse: () => Schedule.morning,
      ),
      profilePicturePath: json['profilePicturePath'] as String?,
      status: EnrollmentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EnrollmentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PersonalInfo {
  final String firstName;
  final String lastName;
  final String middleName;
  final String phoneNumber;
  final String address;
  final DateTime birthDate;

  PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.phoneNumber,
    required this.address,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'phoneNumber': phoneNumber,
      'address': address,
      'birthDate': birthDate.toIso8601String(),
    };
  }

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
    );
  }
}

enum Schedule { morning, afternoon, evening }

enum EnrollmentStatus {
  pending,
  underReview,
  approved,
  rejected,
  paymentRequired,
  completed,
}

class StudyLoad {
  final String id;
  final String userId;
  final String year;
  final String program;
  final List<Subject> subjects;
  final DateTime createdAt;

  StudyLoad({
    required this.id,
    required this.userId,
    required this.year,
    required this.program,
    required this.subjects,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class Subject {
  final String code;
  final String name;
  final String schedule;
  final String instructor;
  final int units;

  Subject({
    required this.code,
    required this.name,
    required this.schedule,
    required this.instructor,
    required this.units,
  });
}
