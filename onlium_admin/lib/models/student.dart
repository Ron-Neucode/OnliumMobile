class Student {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String gender;
  final String program;
  final String yearLevel;
  final String studentType;
  final String? profilePictureUrl;
  final DateTime? enrollmentDate;
  final bool isActive;

  Student({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.address,
    required this.gender,
    required this.program,
    required this.yearLevel,
    required this.studentType,
    this.profilePictureUrl,
    this.enrollmentDate,
    this.isActive = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ??
                '${json['firstName']?.toString() ?? ''} ${json['lastName']?.toString() ?? ''}'.trim(),
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      address: json['address']?.toString(),
      gender: json['gender']?.toString() ?? 'Male',
      program: json['program']?.toString() ??
                json['programCode']?.toString() ??
                json['selectedProgram']?.toString() ??
                'Unknown',
      yearLevel: json['yearLevel']?.toString() ?? 
                 '${json['year']?.toString() ?? '1'}st Year',
      studentType: json['studentType']?.toString() ?? 'New/Incoming Student',
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      enrollmentDate: json['enrollmentDate'] != null 
          ? DateTime.tryParse(json['enrollmentDate'].toString())
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'gender': gender,
      'program': program,
      'yearLevel': yearLevel,
      'studentType': studentType,
      'profilePictureUrl': profilePictureUrl,
      'enrollmentDate': enrollmentDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return fullName.substring(0, min(2, fullName.length)).toUpperCase();
  }

  static int min(int a, int b) => a < b ? a : b;
}
