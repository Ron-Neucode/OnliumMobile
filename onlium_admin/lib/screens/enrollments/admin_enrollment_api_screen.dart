import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'admin_application_details_screen.dart';

import '../../providers/admin_applications_api_provider.dart';

class AdminEnrollmentApiScreen extends StatefulWidget {
  const AdminEnrollmentApiScreen({super.key});

  @override
  State<AdminEnrollmentApiScreen> createState() =>
      _AdminEnrollmentApiScreenState();
}

class _AdminEnrollmentApiScreenState extends State<AdminEnrollmentApiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const String _pendingStatus = 'PendingReview';

  static const String _approvedStatus = 'Approved';

  static const String _rejectedStatus = 'Rejected';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminApplicationsApiProvider>().fetchAllEnrollments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminApplicationsApiProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Enrollment Management'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.fetchAllEnrollments(),
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  icon: const Icon(Icons.hourglass_empty),
                  text: 'Pending (${provider.pendingCount})',
                ),
                Tab(
                  icon: const Icon(Icons.check_circle),
                  text: 'Approved (${provider.approvedCount})',
                ),
                Tab(
                  icon: const Icon(Icons.cancel),
                  text: 'Rejected (${provider.rejectedCount})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  color: Colors.red[50],
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              Expanded(
                child: provider.isLoading && provider.pendingEnrollments.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEnrollmentList(_pendingStatus),
                          _buildEnrollmentList(_approvedStatus),
                          _buildEnrollmentList(_rejectedStatus),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentList(String status) {
    return Consumer<AdminApplicationsApiProvider>(
      builder: (context, provider, child) {
        final enrollments = provider.getEnrollmentsByStatus(status);

        if (enrollments.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllEnrollments(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ${_displayStatus(status).toLowerCase()} enrollments',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAllEnrollments(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              return _buildEnrollmentCard(enrollments[index], status);
            },
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentCard(
    Map<String, dynamic> enrollment,
    String currentStatus,
  ) {
    final firstName = enrollment['firstName']?.toString().trim() ?? '';

    final lastName = enrollment['lastName']?.toString().trim() ?? '';

    final email = enrollment['email']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : email.isNotEmpty
            ? email
            : 'Unnamed Student';

    final studentType = enrollment['studentType']?.toString() ?? '-';

    final programCode = enrollment['programCode']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          fullName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$programCode • ${_getStudentTypeDisplay(studentType)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _getStatusBadge(
          enrollment['status']?.toString() ?? currentStatus,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Student Type', _getStudentTypeDisplay(studentType)),
                _buildDetailRow('Program', programCode),
                _buildDetailRow(
                  'Year Level',
                  enrollment['yearLevel']?.toString() ?? '-',
                ),
                _buildDetailRow(
                  'Semester',
                  enrollment['semester']?.toString() ?? '-',
                ),
                _buildDetailRow(
                  'Schedule',
                  enrollment['preferredSchedule']?.toString() ?? '-',
                ),
                _buildDetailRow(
                  'Submitted Date',
                  _formatDate(enrollment['submittedAt']),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AdminApplicationDetailsScreen(
                            applicationId: enrollment['id'].toString(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Review Requirements'),
                  ),
                ),
                if (currentStatus == _pendingStatus) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showApproveDialog(context, enrollment),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showRejectDialog(context, enrollment),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
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
            width: 120,
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
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;

    IconData icon;

    switch (status) {
      case _pendingStatus:
        color = Colors.orange;

        icon = Icons.hourglass_empty;

        break;

      case _approvedStatus:
        color = Colors.green;

        icon = Icons.check_circle;

        break;

      case _rejectedStatus:
        color = Colors.red;

        icon = Icons.cancel;

        break;

      default:
        color = Colors.grey;

        icon = Icons.info;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(_displayStatus(status)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  String _displayStatus(String status) {
    switch (status) {
      case _pendingStatus:
        return 'Pending';

      case _approvedStatus:
        return 'Approved';

      case _rejectedStatus:
        return 'Rejected';

      default:
        return status;
    }
  }

  String _getStudentTypeDisplay(String type) {
    switch (type) {
      case 'NewIncoming':
        return 'New/Incoming';

      case 'Transferee':
        return 'Transferee';

      case 'Continuing':
        return 'Continuing';

      default:
        return type;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final raw = value.toString();

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return raw;

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }

  void _showApproveDialog(
    BuildContext context,
    Map<String, dynamic> enrollment,
  ) {
    final locationController = TextEditingController(text: 'School Campus');

    final notesController = TextEditingController(
      text:
          'Please proceed to the school cashier to pay your required downpayment for this semester and complete your enrollment.',
    );

    DateTime? selectedDate;

    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Approve and Schedule Appointment'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set the student appointment before approval.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Instructions',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );

                              if (pickedDate != null) {
                                setDialogState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              selectedDate == null
                                  ? 'Select Date'
                                  : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (pickedTime != null) {
                                setDialogState(() {
                                  selectedTime = pickedTime;
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              selectedTime == null
                                  ? 'Select Time'
                                  : selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null || selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select appointment date and time.'),
                        backgroundColor: Colors.orange,
                      ),
                    );

                    return;
                  }

                  final appointmentDate = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  final provider = context.read<AdminApplicationsApiProvider>();

                  final approved = await provider.approveEnrollment(
                    enrollment['id'].toString(),
                  );

                  if (!mounted) return;

                  if (!approved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ??
                              'Failed to approve enrollment.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );

                    return;
                  }

                  final scheduled = await provider.createAppointment(
                    applicationId: enrollment['id'].toString(),
                    appointmentDate: appointmentDate,
                    location: locationController.text,
                    notes: notesController.text,
                  );

                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        scheduled
                            ? 'Enrollment approved and appointment scheduled.'
                            : (provider.errorMessage ??
                                'Enrollment approved, but appointment scheduling failed.'),
                      ),
                      backgroundColor: scheduled ? Colors.green : Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve & Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    Map<String, dynamic> enrollment,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );

                return;
              }

              final success = await context
                  .read<AdminApplicationsApiProvider>()
                  .rejectEnrollment(enrollment['id'].toString(), reason);

              if (!mounted) return;

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Enrollment rejected successfully.'
                        : (context
                                .read<AdminApplicationsApiProvider>()
                                .errorMessage ??
                            'Failed to reject enrollment.'),
                  ),
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
