class User {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final StudentType studentType;
  final bool isLoggedIn;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.studentType,
    this.isLoggedIn = false,
  });

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    StudentType? studentType,
    bool? isLoggedIn,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      studentType: studentType ?? this.studentType,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'studentType': studentType.toString(),
      'isLoggedIn': isLoggedIn,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
      studentType: StudentType.values.firstWhere(
        (e) => e.toString() == json['studentType'],
        orElse: () => StudentType.newIncoming,
      ),
      isLoggedIn: json['isLoggedIn'] ?? false,
    );
  }
}

enum StudentType { newIncoming, transferee, continuing }
