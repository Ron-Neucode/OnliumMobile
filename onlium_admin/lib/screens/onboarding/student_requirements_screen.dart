import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/enrollment_management_provider.dart';

class StudentRequirementsScreen extends StatefulWidget {
  const StudentRequirementsScreen({super.key});

  @override
  State<StudentRequirementsScreen> createState() => _StudentRequirementsScreenState();
}

class _StudentRequirementsScreenState extends State<StudentRequirementsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Student Requirements Check'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<EnrollmentManagementProvider>(
        builder: (context, provider, child) {
          final pendingEnrollments = provider.getEnrollmentsByStatus(EnrollmentStatus.pending);
          
          if (pendingEnrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requirements to check',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: pendingEnrollments.length,
            itemBuilder: (context, index) {
              return _buildRequirementsCard(pendingEnrollments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequirementsCard(EnrollmentRequest enrollment) {
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
              color: Colors.purple[50],
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
                    Icon(Icons.person, color: Colors.purple[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enrollment.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(enrollment.studentType.toString().split('.')[1]),
                      backgroundColor: Colors.purple[100],
                      labelStyle: TextStyle(color: Colors.purple[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${enrollment.program}',
                  style: TextStyle(color: Colors.purple[600]),
                ),
                Text(
                  'Email: ${enrollment.studentEmail}',
                  style: TextStyle(color: Colors.purple[600]),
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
                  'Requirements Checklist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRequirementItem('Application Form', true),
                _buildRequirementItem('Transcript of Records', false),
                _buildRequirementItem('Birth Certificate', true),
                _buildRequirementItem('Certificate of Good Moral', false),
                _buildRequirementItem('2x2 ID Picture', true),
                _buildRequirementItem('Parent\'s Consent', enrollment.studentType == StudentType.newIncoming),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(enrollment),
                        icon: const Icon(Icons.check),
                        label: const Text('Requirements Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showIncompleteDialog(enrollment),
                        icon: const Icon(Icons.pending),
                        label: const Text('Incomplete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
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

  Widget _buildRequirementItem(String requirement, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isComplete ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            requirement,
            style: TextStyle(
              color: isComplete ? Colors.black87 : Colors.grey[600],
              decoration: isComplete ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Requirements Complete'),
        content: Text('Are you sure ${enrollment.studentName} has completed all requirements?'),
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
                  content: Text('Requirements verified! Student can proceed to next step.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showIncompleteDialog(EnrollmentRequest enrollment) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incomplete Requirements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please specify which requirements are missing:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Missing Requirements',
                border: OutlineInputBorder(),
                hintText: 'e.g., Transcript, Certificate of Good Moral',
              ),
              maxLines: 3,
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
                  content: Text('Notification sent to ${enrollment.studentName} regarding incomplete requirements.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send Notification'),
          ),
        ],
      ),
    );
  }
}
