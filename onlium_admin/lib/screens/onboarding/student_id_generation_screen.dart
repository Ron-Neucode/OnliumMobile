import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/enrollment_management_provider.dart';

class StudentIDGenerationScreen extends StatefulWidget {
  const StudentIDGenerationScreen({super.key});

  @override
  State<StudentIDGenerationScreen> createState() => _StudentIDGenerationScreenState();
}

class _StudentIDGenerationScreenState extends State<StudentIDGenerationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Student ID Generation'),
        backgroundColor: Colors.red[700],
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
                  Icon(Icons.badge, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No students available for ID generation',
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
              return _buildIDCard(approvedEnrollments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildIDCard(EnrollmentRequest enrollment) {
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
              color: Colors.red[50],
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
                    Icon(Icons.person, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enrollment.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(enrollment.studentType.toString().split('.')[1]),
                      backgroundColor: Colors.red[100],
                      labelStyle: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${enrollment.program}',
                  style: TextStyle(color: Colors.red[600]),
                ),
                Text(
                  'Email: ${enrollment.studentEmail}',
                  style: TextStyle(color: Colors.red[600]),
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
                  'Student ID Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildIDInfo('ID Number', 'Not Generated'),
                _buildIDInfo('ID Type', 'Student ID Card'),
                _buildIDInfo('Validity', 'Not Set'),
                _buildIDInfo('Status', 'Not Generated'),
                const SizedBox(height: 16),
                const Text(
                  'ID Card Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'ID Card Preview',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Will appear here after generation',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showGenerateIDDialog(enrollment),
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Generate ID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPrintDialog(enrollment),
                        icon: const Icon(Icons.print),
                        label: const Text('Print'),
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

  Widget _buildIDInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
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
              color: value == 'Not Generated' || value == 'Not Set'
                ? Colors.red[600]
                : Colors.black87,
              fontWeight: value == 'Not Generated' || value == 'Not Set'
                ? FontWeight.w600
                : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showGenerateIDDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Student ID: ${enrollment.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will generate a student ID card with the following details:'),
            const SizedBox(height: 12),
            _buildDialogInfo('ID Number', 'STU-${DateTime.now().year}-${enrollment.id.substring(0, 6).toUpperCase()}'),
            _buildDialogInfo('Full Name', enrollment.studentName),
            _buildDialogInfo('Program', enrollment.program),
            _buildDialogInfo('Student Type', enrollment.studentType.toString().split('.')[1]),
            _buildDialogInfo('Valid Until', 'June 30, 2025'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student can use this ID for campus access and services.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
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
                  content: Text('Student ID generated for ${enrollment.studentName}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Generate ID'),
          ),
        ],
      ),
    );
  }

  void _showPrintDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Print Student ID: ${enrollment.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select printing options:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Standard'),
                    value: 'standard',
                    groupValue: 'standard',
                    onChanged: (value) {},
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Premium'),
                    value: 'premium',
                    groupValue: 'standard',
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Number of copies:'),
            Row(
              children: [
                for (int i = 1; i <= 3; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: i == 1 ? Colors.red[700] : Colors.grey[200],
                          foregroundColor: i == 1 ? Colors.white : Colors.black87,
                        ),
                        child: Text('$i'),
                      ),
                    ),
                  ),
              ],
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
                const SnackBar(
                  content: Text('ID sent to printer!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Print'),
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
            width: 80,
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
}
