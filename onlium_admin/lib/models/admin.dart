class Admin {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final AdminRole role;
  final bool isLoggedIn;

  Admin({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.isLoggedIn = false,
  });

  Admin copyWith({
    String? id,
    String? email,
    String? password,
    String? fullName,
    AdminRole? role,
    bool? isLoggedIn,
  }) {
    return Admin(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role.toString(),
      'isLoggedIn': isLoggedIn,
    };
  }

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['fullName'] as String,
      role: AdminRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => AdminRole.administrator,
      ),
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
    );
  }
}

enum AdminRole { administrator }
