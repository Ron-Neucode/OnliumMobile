import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_study_load_schedule_provider.dart';

class AdminStudyLoadScheduleValidationScreen extends StatefulWidget {
  const AdminStudyLoadScheduleValidationScreen({super.key});

  @override
  State<AdminStudyLoadScheduleValidationScreen> createState() =>
      _AdminStudyLoadScheduleValidationScreenState();
}

class _AdminStudyLoadScheduleValidationScreenState
    extends State<AdminStudyLoadScheduleValidationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStudyLoadScheduleProvider>().fetchAllSchedules();
    });
  }

  String _displayStatus(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'pendingreview':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'pendingreview':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
            ? parsed.hour - 12
            : parsed.hour;

    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';

    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} $hour:$minute $period';
  }

  String _yearLabel(dynamic value) {
    final year = int.tryParse(value?.toString() ?? '');

    switch (year) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      default:
        return 'Year ${value ?? '-'}';
    }
  }

  String _semesterLabel(dynamic value) {
    final semester = int.tryParse(value?.toString() ?? '');

    switch (semester) {
      case 1:
        return '1st Semester';
      case 2:
        return '2nd Semester';
      case 3:
        return 'Summer';
      default:
        return 'Semester ${value ?? '-'}';
    }
  }

  Future<void> _openDetails(Map<String, dynamic> schedule) async {
    final provider = context.read<AdminStudyLoadScheduleProvider>();
    final id = schedule['id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid schedule ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final details = await provider.fetchScheduleDetails(id);

      if (!mounted) return;
      Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder: (_) => _ScheduleDetailsDialog(
          details: details,
          onApprove: () => _approveSchedule(details),
          onReject: () => _showRejectDialog(details),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveSchedule(Map<String, dynamic> details) async {
    final id = details['id']?.toString();

    if (id == null || id.isEmpty) return;

    final provider = context.read<AdminStudyLoadScheduleProvider>();
    final success = await provider.approveSchedule(id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study load schedule approved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Approval failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> details) async {
    final id = details['id']?.toString();

    if (id == null || id.isEmpty) return;

    final commentController = TextEditingController();

    final comment = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Schedule'),
        content: TextField(
          controller: commentController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason / Comment',
            hintText: 'Explain what needs to be corrected.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, commentController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    commentController.dispose();

    if (comment == null || comment.trim().isEmpty) return;

    if (!mounted) return;

    final provider = context.read<AdminStudyLoadScheduleProvider>();
    final success = await provider.rejectSchedule(
      id: id,
      comment: comment,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study load schedule rejected successfully.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Rejection failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildScheduleList(
    String status,
    AdminStudyLoadScheduleProvider provider,
  ) {
    final schedules = provider.getSchedulesByStatus(status);

    if (schedules.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.fetchAllSchedules,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Icon(
              status == 'PendingReview'
                  ? Icons.hourglass_empty
                  : status == 'Approved'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 70,
              color: Colors.white70,
            ),
            const SizedBox(height: 18),
            Text(
              status == 'PendingReview'
                  ? 'No pending study load schedules'
                  : 'No ${status.toLowerCase()} study load schedules',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchAllSchedules,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return _buildScheduleCard(schedule);
        },
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final status = schedule['status']?.toString() ?? 'PendingReview';
    final color = _statusColor(status);

    final studentName =
        schedule['studentName']?.toString() ?? 'Unknown Student';
    final email = schedule['email']?.toString() ?? '-';
    final programCode = schedule['programCode']?.toString() ?? '-';
    final yearLevel = _yearLabel(schedule['yearLevel']);
    final semester = _semesterLabel(schedule['semester']);
    final subjectCount = schedule['subjectCount']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.fact_check, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _displayStatus(status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: color.withOpacity(0.12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoText(Icons.email_outlined, email),
            _infoText(
              Icons.school_outlined,
              '$programCode • $yearLevel • $semester',
            ),
            _infoText(Icons.menu_book, '$subjectCount subject(s) submitted'),
            _infoText(
              Icons.access_time,
              'Submitted: ${_formatDate(schedule['submittedAt'] ?? schedule['createdAt'])}',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDetails(schedule),
                icon: const Icon(Icons.visibility),
                label: const Text('Review Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminStudyLoadScheduleProvider>(
      builder: (context, provider, child) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Study Load Validation'),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed:
                      provider.isLoading ? null : provider.fetchAllSchedules,
                  icon: const Icon(Icons.refresh),
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Pending (${provider.pendingCount})'),
                  Tab(text: 'Approved (${provider.approvedCount})'),
                  Tab(text: 'Rejected (${provider.rejectedCount})'),
                ],
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3F7ED8),
                    Color(0xFF8EC7FF),
                    Color(0xFFD6ECFF),
                  ],
                ),
              ),
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Column(
                      children: [
                        if (provider.errorMessage != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Text(
                              provider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildScheduleList('PendingReview', provider),
                              _buildScheduleList('Approved', provider),
                              _buildScheduleList('Rejected', provider),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> details;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ScheduleDetailsDialog({
    required this.details,
    required this.onApprove,
    required this.onReject,
  });

  String _displayStatus(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'pendingreview':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'pendingreview':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _yearLabel(dynamic value) {
    final year = int.tryParse(value?.toString() ?? '');

    switch (year) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      default:
        return 'Year ${value ?? '-'}';
    }
  }

  String _semesterLabel(dynamic value) {
    final semester = int.tryParse(value?.toString() ?? '');

    switch (semester) {
      case 1:
        return '1st Semester';
      case 2:
        return '2nd Semester';
      case 3:
        return 'Summer';
      default:
        return 'Semester ${value ?? '-'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = details['status']?.toString() ?? '-';
    final color = _statusColor(status);

    final itemsRaw = details['items'];
    final items = itemsRaw is List
        ? itemsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final isPending =
        status.trim().replaceAll(' ', '').toLowerCase() == 'pendingreview';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          children: [
            AppBar(
              title: const Text('Review Study Load Schedule'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color,
                        child:
                            const Icon(Icons.fact_check, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _displayStatus(status),
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                    'Student',
                    details['studentName']?.toString() ?? '-',
                  ),
                  _detailRow(
                    'Email',
                    details['email']?.toString() ?? '-',
                  ),
                  _detailRow(
                    'Term',
                    '${details['programCode'] ?? '-'} • ${_yearLabel(details['yearLevel'])} • ${_semesterLabel(details['semester'])}',
                  ),
                  if (details['adminComment'] != null &&
                      details['adminComment'].toString().trim().isNotEmpty)
                    _detailRow(
                      'Admin Comment',
                      details['adminComment'].toString(),
                    ),
                  const SizedBox(height: 18),
                  const Text(
                    'Submitted Subjects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Text('No submitted subjects found.')
                  else
                    ...items.map(_subjectItemCard),
                ],
              ),
            ),
            if (isPending)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _subjectItemCard(Map<String, dynamic> item) {
    final subjectCode = item['subjectCode']?.toString() ?? '-';
    final subjectTitle = item['subjectTitle']?.toString() ?? '-';
    final section = item['section']?.toString() ?? '-';
    final professor = item['professorName']?.toString() ?? '-';
    final days = item['days']?.toString() ?? '-';
    final startTime = item['startTime']?.toString() ?? '-';
    final endTime = item['endTime']?.toString() ?? '-';
    final room = item['room']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$subjectCode - $subjectTitle',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            _miniRow('Section', section),
            _miniRow('Professor', professor),
            _miniRow('Days', days),
            _miniRow('Time', '$startTime - $endTime'),
            _miniRow('Room', room),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
