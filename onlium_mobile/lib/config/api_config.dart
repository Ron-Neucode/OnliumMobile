class ApiConfig {
  // Backend ports from your ASP.NET launchSettings:
  // HTTPS: https://localhost:7164
  // HTTP:  http://localhost:5027

  // Use this for Flutter Windows desktop or Chrome.
  static const String baseUrlWindows = "https://localhost:7164";

  // Use this for Android emulator.
  // If HTTPS gives certificate error, tell me. We will switch backend/dev config.
  static const String baseUrlAndroidEmulator = "https://10.0.2.2:7164";

  // Use this for physical phone on same Wi-Fi.
  // Replace with your PC IPv4 address.
  static const String baseUrlPhone = "https://192.168.1.100:7164";

  // Change only this depending on where you run Flutter.
  static const String baseUrl = baseUrlWindows;
}
