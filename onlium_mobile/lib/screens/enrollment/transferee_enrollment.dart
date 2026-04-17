import 'package:flutter/material.dart';
import 'package:onlium_mobile/models/user.dart';
import '../../models/enrollment.dart';
import 'enrollment_screen.dart';

class TransfereeEnrollment extends StatelessWidget {
  const TransfereeEnrollment({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseEnrollmentScreen(
      studentType: StudentType.transferee,
      requiredDocuments: const [
        'Transcript of Records (TOR)',
        'Honorable Dismissal',
      ],
      child: Container(), // The BaseEnrollmentScreen handles everything
    );
  }
}
