import 'package:flutter/material.dart';
import 'enrollment_screen.dart';

class TransfereeEnrollment extends StatelessWidget {
  const TransfereeEnrollment({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseEnrollmentScreen(
      studentType: EnrollmentStudentType.transferee,
      requiredDocuments: ['Transcript of Records (TOR)', 'Honorable Dismissal'],
    );
  }
}
