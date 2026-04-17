# Onlium Admin - Enrollment Management System

## Overview

This is the **admin portal** for the Onlium Online Enrollment System. Administrators can manage student enrollments, review submissions, and maintain the enrollment system.

## Features

### 👨‍💼 Admin Dashboard

- Overview of enrollment statistics
- Quick access to pending, approved, and rejected enrollments
- Key metrics visualization

### 📋 Enrollment Management

- View all student enrollment requests
- Review detailed enrollment information
- Approve enrollments with notes
- Reject enrollments with reasons
- Filter by status (Pending, Approved, Rejected)

### 🔐 Security

- Admin login with email and password
- Multiple admin roles (Super Admin, Enrollment Officer, Academic Officer)
- Session persistence with SharedPreferences

## Admin Demo Credentials

### Super Admin

- **Email**: admin@onlium.com
- **Password**: admin123

### Enrollment Officer

- **Email**: enrollment@onlium.com
- **Password**: enroll123

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **SharedPreferences**: Local data persistence

## Architecture

### Models

- `Admin`: Admin user model with role-based access
- `EnrollmentRequest`: Enrollment submission model
- `StudentType` & `EnrollmentStatus`: Enums for categorization

### Providers

- `AdminAuthProvider`: Authentication and session management
- `EnrollmentManagementProvider`: Enrollment review and approval

### Screens

- **Admin Login**: Authentication interface
- **Admin Dashboard**: Overview and quick actions
- **Enrollment Management**: Detailed enrollment review interface

## Future Enhancements

When backend API is ready (Swagger):

1. Replace SharedPreferences with API calls
2. Add real-time notifications for new enrollments
3. Advanced filtering and search
4. Export reports to PDF/Excel
5. Student management interface
6. Course schedule management
7. Analytics dashboard

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK
- Android Studio or Xcode (for mobile)

### Installation

```bash
cd onlium_admin
flutter pub get
flutter run
```

Choose a device:

- [1] Windows (desktop)
- [2] Chrome (web)

## Project Structure

```
onlium_admin/
├── lib/
│   ├── models/
│   │   ├── admin.dart
│   │   ├── enrollment_request.dart
│   │   └── shared.dart
│   ├── providers/
│   │   ├── admin_auth_provider.dart
│   │   └── enrollment_management_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   └── enrollments/
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Notes

- Data is stored locally using SharedPreferences
- Admin accounts are initialized on first run
- All dialogs and notifications use Flutter's built-in widgets
- Responsive UI works on all device sizes

---

**Developer**: Built with ❤️ using Flutter
