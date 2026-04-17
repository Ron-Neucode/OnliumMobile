import 'package:flutter/material.dart';
import 'package:onlium_mobile/models/user.dart';
import '../../models/enrollment.dart';
import 'enrollment_screen.dart';

class NewIncomingEnrollment extends StatelessWidget {
  const NewIncomingEnrollment({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseEnrollmentScreen(
      studentType: StudentType.newIncoming,
      requiredDocuments: const [
        'Report Card',
        'Good Moral Certificate',
        'PSA Birth Certificate',
      ],
      child: Container(), // The BaseEnrollmentScreen handles everything
    );
  }
}
