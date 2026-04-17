import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../enrollment/enrollment_screen.dart';
import '../../models/enrollment.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context);
    final user = authProvider.currentUser!;
    final userEnrollments = enrollmentProvider.getEnrollmentsByUserId(user.id);
    final latestEnrollment = <Enrollment>[...userEnrollments];
    latestEnrollment.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Enrollment? enrollment = latestEnrollment.isEmpty
        ? null
        : latestEnrollment.first;

    String statusText;
    Widget statusContent;
    if (enrollment == null) {
      statusText = 'No Enrollment Found';
      statusContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No enrollment request was found for your account yet.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EnrollmentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Submit Enrollment Request'),
          ),
        ],
      );
    } else if (enrollment.status == EnrollmentStatus.approved ||
        enrollment.status == EnrollmentStatus.completed ||
        enrollment.status == EnrollmentStatus.paymentRequired) {
      statusText = 'Approved';
      statusContent = const Text(
        'Greeting! Your enrollment request has been approved. Please proceed to our main campus here at Northpoint Business Center, M.C. Briones St., Maguikay, Mandaue City. Please proceed to our admission office near the gate and show this form as proof of enrollment. Prepare the exact amount of 2,750 pesos for downpayment and proceed to the cashier to finish your enrollment. Thank you for enrolling on our campus.',
        style: TextStyle(fontSize: 16, height: 1.5),
      );
    } else if (enrollment.status == EnrollmentStatus.rejected) {
      statusText = 'Rejected';
      statusContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sorry, your enrollment request has been rejected by the admin. Please submit a new enrollment request or contact the admin for assistance. Thank you.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EnrollmentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Resubmit Enrollment'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Contact Admin'),
                  content: const Text(
                    'Please contact the admin for concerns regarding your enrollment request.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Contact Admin'),
          ),
        ],
      );
    } else {
      statusText = 'Pending Review';
      statusContent = const Text(
        'Your enrollment request is currently under review. Please wait for the admin to update your request and check back here later.',
        style: TextStyle(fontSize: 16, height: 1.5),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Appointment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3F7ED8), Color(0xFF8EC7FF), Color(0xFFD6ECFF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16.0,
              MediaQuery.of(context).padding.top + kToolbarHeight + 24.0,
              16.0,
              24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Status',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (enrollment != null)
                              Flexible(
                                child: Text(
                                  'Requested: ${enrollment.createdAt.month}/${enrollment.createdAt.day}/${enrollment.createdAt.year}',
                                  style: TextStyle(color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        statusContent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
