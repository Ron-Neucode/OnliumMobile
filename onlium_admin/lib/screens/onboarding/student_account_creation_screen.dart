import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/enrollment_management_provider.dart';

class StudentAccountCreationScreen extends StatefulWidget {
  const StudentAccountCreationScreen({super.key});

  @override
  State<StudentAccountCreationScreen> createState() => _StudentAccountCreationScreenState();
}

class _StudentAccountCreationScreenState extends State<StudentAccountCreationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Student Account Creation'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<EnrollmentManagementProvider>(
        builder: (context, provider, child) {
          final approvedEnrollments = provider.getEnrollmentsByStatus(EnrollmentStatus.approved);
          
          if (approvedEnrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No approved students for account creation',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedEnrollments.length,
            itemBuilder: (context, index) {
              return _buildAccountCard(approvedEnrollments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(EnrollmentRequest enrollment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enrollment.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(enrollment.studentType.toString().split('.')[1]),
                      backgroundColor: Colors.green[100],
                      labelStyle: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${enrollment.program}',
                  style: TextStyle(color: Colors.green[600]),
                ),
                Text(
                  'Email: ${enrollment.studentEmail}',
                  style: TextStyle(color: Colors.green[600]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAccountInfo('Student ID', 'Not Generated'),
                _buildAccountInfo('Username', 'Not Created'),
                _buildAccountInfo('Password', 'Not Generated'),
                _buildAccountInfo('Account Status', 'Inactive'),
                const SizedBox(height: 16),
                const Text(
                  'System Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAccessItem('Student Portal', false),
                _buildAccessItem('Library System', false),
                _buildAccessItem('Email System', false),
                _buildAccessItem('Learning Management', false),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateAccountDialog(enrollment),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCredentialsDialog(enrollment),
                        icon: const Icon(Icons.key),
                        label: const Text('View Credentials'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: value == 'Not Generated' || value == 'Not Created' || value == 'Inactive'
                ? Colors.red[600]
                : Colors.black87,
              fontWeight: value == 'Not Generated' || value == 'Not Created' || value == 'Inactive'
                ? FontWeight.w600
                : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessItem(String system, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            hasAccess ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: hasAccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            system,
            style: TextStyle(
              color: hasAccess ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAccountDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Account: ${enrollment.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will create a student account with the following:'),
            const SizedBox(height: 12),
            _buildDialogInfo('Student ID', 'STU-${DateTime.now().year}-${enrollment.id.substring(0, 6).toUpperCase()}'),
            _buildDialogInfo('Username', '${enrollment.studentEmail.split('@')[0]}${enrollment.id.substring(0, 3)}'),
            _buildDialogInfo('Temporary Password', 'Temp@123'),
            const SizedBox(height: 8),
            Text(
              'The student will receive login credentials via email.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account created for ${enrollment.studentName}! Credentials sent to email.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  void _showCredentialsDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Credentials: ${enrollment.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Account credentials will be displayed here once created.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildCredentialItem('Student ID', 'Not Available'),
                  _buildCredentialItem('Username', 'Not Available'),
                  _buildCredentialItem('Password', 'Not Available'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
