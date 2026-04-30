import "dart:convert";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../config/api_config.dart";
import "../models/auth_response.dart";

class AuthService {
  static Future<String?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/Auth/register");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json", "Accept": "*/*"},
      body: jsonEncode({
        "email": email.trim(),
        "password": password.trim(),
        "firstName": firstName.trim(),
        "lastName": lastName.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["message"]?.toString() ?? "Student registered successfully.";
    }

    try {
      final data = jsonDecode(response.body);
      return data["message"]?.toString() ?? "Registration failed.";
    } catch (_) {
      return "Registration failed. Status: ${response.statusCode}";
    }
  }

  static Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/api/Auth/login");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json", "Accept": "*/*"},
      body: jsonEncode({"email": email.trim(), "password": password.trim()}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final auth = AuthResponse.fromJson(data);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", auth.token);
      await prefs.setString("email", auth.email);
      await prefs.setString("fullName", auth.fullName);
      await prefs.setString("role", auth.role);

      return auth;
    }

    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("email");
    await prefs.remove("fullName");
    await prefs.remove("role");
  }
}
