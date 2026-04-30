class ApiConfig {
  // Windows desktop
  static const String baseUrlWindows = "https://localhost:7164";

  // Android emulator
  static const String baseUrlAndroidEmulator = "https://10.0.2.2:7164";

  // Physical phone on same Wi-Fi
  // Replace with your PC IPv4 address
  static const String baseUrlPhone = "https://192.168.1.100:7164";

  // Change this depending on your target
  static const String baseUrl = baseUrlWindows;
}
