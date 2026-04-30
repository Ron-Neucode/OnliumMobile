import 'package:flutter/material.dart';
import 'enrollment_screen.dart';

class NewIncomingEnrollment extends StatelessWidget {
  const NewIncomingEnrollment({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseEnrollmentScreen(
      studentType: EnrollmentStudentType.newIncoming,
      requiredDocuments: [
        'Report Card',
        'Good Moral Certificate',
        'PSA Birth Certificate',
      ],
    );
  }
}
