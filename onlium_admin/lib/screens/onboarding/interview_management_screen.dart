import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/enrollment_management_provider.dart';

class InterviewManagementScreen extends StatefulWidget {
  const InterviewManagementScreen({super.key});

  @override
  State<InterviewManagementScreen> createState() => _InterviewManagementScreenState();
}

class _InterviewManagementScreenState extends State<InterviewManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Student Interviews'),
        backgroundColor: Colors.indigo[700],
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
                  Icon(Icons.people, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No interviews scheduled',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingEnrollments.length,
            itemBuilder: (context, index) {
              return _buildInterviewCard(pendingEnrollments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildInterviewCard(EnrollmentRequest enrollment) {
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
              color: Colors.indigo[50],
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
                    Icon(Icons.person, color: Colors.indigo[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enrollment.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700],
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(enrollment.studentType.toString().split('.')[1]),
                      backgroundColor: Colors.indigo[100],
                      labelStyle: TextStyle(color: Colors.indigo[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${enrollment.program}',
                  style: TextStyle(color: Colors.indigo[600]),
                ),
                Text(
                  'Email: ${enrollment.studentEmail}',
                  style: TextStyle(color: Colors.indigo[600]),
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
                  'Interview Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInterviewSchedule('Date', 'June 15, 2024'),
                _buildInterviewSchedule('Time', '10:00 AM'),
                _buildInterviewSchedule('Location', 'Admissions Office'),
                _buildInterviewSchedule('Interviewer', 'Ms. Sarah Johnson'),
                const SizedBox(height: 16),
                const Text(
                  'Interview Checklist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildChecklistItem('Academic Background'),
                _buildChecklistItem('Career Goals'),
                _buildChecklistItem('Extracurricular Activities'),
                _buildChecklistItem('Personal Motivation'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showConductDialog(enrollment),
                        icon: const Icon(Icons.record_voice_over),
                        label: const Text('Conduct Interview'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRescheduleDialog(enrollment),
                        icon: const Icon(Icons.schedule),
                        label: const Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
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

  Widget _buildInterviewSchedule(String label, String value) {
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
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(item, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showConductDialog(EnrollmentRequest enrollment) {
    final notesController = TextEditingController();
    String selectedDecision = 'pending';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Interview: ${enrollment.studentName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Interview Notes:'),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Enter interview observations...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Admission Decision:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Radio<String>(
                      value: 'accept',
                      groupValue: selectedDecision,
                      onChanged: (value) => setState(() => selectedDecision = value!),
                    ),
                  ),
                  const Text('Accept'),
                  Expanded(
                    child: Radio<String>(
                      value: 'reject',
                      groupValue: selectedDecision,
                      onChanged: (value) => setState(() => selectedDecision = value!),
                    ),
                  ),
                  const Text('Reject'),
                  Expanded(
                    child: Radio<String>(
                      value: 'pending',
                      groupValue: selectedDecision,
                      onChanged: (value) => setState(() => selectedDecision = value!),
                    ),
                  ),
                  const Text('Pending'),
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
                String message = selectedDecision == 'accept' 
                  ? 'Student accepted for admission!'
                  : selectedDecision == 'reject'
                  ? 'Student rejected.'
                  : 'Decision pending further review.';
                  
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: selectedDecision == 'accept' 
                      ? Colors.green 
                      : selectedDecision == 'reject' 
                      ? Colors.red 
                      : Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700]),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(EnrollmentRequest enrollment) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reschedule Interview: ${enrollment.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'New Date',
                border: OutlineInputBorder(),
                hintText: 'e.g., June 20, 2024',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'New Time',
                border: OutlineInputBorder(),
                hintText: 'e.g., 2:00 PM',
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
              if (dateController.text.isEmpty || timeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Interview rescheduled to ${dateController.text} at ${timeController.text}'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }
}
