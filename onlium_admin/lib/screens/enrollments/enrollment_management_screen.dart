import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/enrollment_management_provider.dart';

class EnrollmentManagementScreen extends StatefulWidget {
  const EnrollmentManagementScreen({super.key});

  @override
  State<EnrollmentManagementScreen> createState() =>
      _EnrollmentManagementScreenState();
}

class _EnrollmentManagementScreenState extends State<EnrollmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Enrollment Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Approved'),
            Tab(icon: Icon(Icons.cancel), text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEnrollmentList(EnrollmentStatus.pending),
          _buildEnrollmentList(EnrollmentStatus.approved),
          _buildEnrollmentList(EnrollmentStatus.rejected),
        ],
      ),
    );
  }

  Widget _buildEnrollmentList(EnrollmentStatus status) {
    return Consumer<EnrollmentManagementProvider>(
      builder: (context, provider, child) {
        final enrollments = provider.getEnrollmentsByStatus(status);

        if (enrollments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ${status.toString().split('.')[1]} enrollments',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            return _buildEnrollmentCard(enrollments[index], context, status);
          },
        );
      },
    );
  }

  Widget _buildEnrollmentCard(
    EnrollmentRequest enrollment,
    BuildContext context,
    EnrollmentStatus currentStatus,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          enrollment.studentName,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          enrollment.program,
          style: TextStyle(fontSize: 12),
        ),
        trailing: _getStatusBadge(enrollment.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', enrollment.studentEmail),
                _buildDetailRow(
                  'Student Type',
                  _getStudentTypeDisplay(enrollment.studentType),
                ),
                _buildDetailRow('Program', enrollment.program),
                _buildDetailRow(
                  'Submitted Date',
                  enrollment.submittedAt.toString().split('.')[0],
                ),
                if (enrollment.reviewedAt != null)
                  _buildDetailRow(
                    'Reviewed Date',
                    enrollment.reviewedAt.toString().split('.')[0],
                  ),
                if (enrollment.reviewNotes != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Review Notes', enrollment.reviewNotes ?? ''),
                ],
                if (currentStatus == EnrollmentStatus.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showApproveDialog(context, enrollment);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showRejectDialog(context, enrollment);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(EnrollmentStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case EnrollmentStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case EnrollmentStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case EnrollmentStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(status.toString().split('.')[1]),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  String _getStudentTypeDisplay(StudentType type) {
    switch (type) {
      case StudentType.newIncoming:
        return 'New/Incoming';
      case StudentType.transferee:
        return 'Transferee';
      case StudentType.continuing:
        return 'Continuing';
    }
  }

  void _showApproveDialog(BuildContext context, EnrollmentRequest enrollment) {
    final notesController = TextEditingController();
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Enrollment'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Approval Notes (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<EnrollmentManagementProvider>(
                context,
                listen: false,
              ).approveEnrollment(
                enrollment.id,
                authProvider.currentAdmin!.id,
                notesController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enrollment approved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, EnrollmentRequest enrollment) {
    final reasonController = TextEditingController();
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Enrollment'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Provider.of<EnrollmentManagementProvider>(
                context,
                listen: false,
              ).rejectEnrollment(
                enrollment.id,
                authProvider.currentAdmin!.id,
                reasonController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enrollment rejected!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
