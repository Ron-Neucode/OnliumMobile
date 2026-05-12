import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



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



  static const String _pendingStatus = 'PendingReview';

  static const String _approvedStatus = 'Approved';

  static const String _rejectedStatus = 'Rejected';



  @override

  void initState() {

    super.initState();

    _tabController = TabController(length: 3, vsync: this);



    WidgetsBinding.instance.addPostFrameCallback((_) {

      context.read<EnrollmentManagementProvider>().fetchPendingEnrollments();

    });

  }



  @override

  void dispose() {

    _tabController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Consumer<EnrollmentManagementProvider>(

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

                    : () => provider.fetchPendingEnrollments(),

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

                  'No ${_displayStatus(status).toLowerCase()} enrollments',

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

            return _buildEnrollmentCard(enrollments[index], status);

          },

        );

      },

    );

  }



  Widget _buildEnrollmentCard(

    Map<String, dynamic> enrollment,

    String currentStatus,

  ) {

    final firstName = enrollment['firstName']?.toString() ?? '';

    final lastName = enrollment['lastName']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim().isEmpty

        ? 'Unnamed Student'

        : '$firstName $lastName'.trim();



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

                  'Phone Number',

                  enrollment['phoneNumber']?.toString() ?? '-',

                ),

                _buildDetailRow(

                  'Address',

                  enrollment['address']?.toString() ?? '-',

                ),

                _buildDetailRow(

                  'Birth Date',

                  _formatDate(enrollment['birthDate']),

                ),

                _buildDetailRow(

                  'Submitted Date',

                  _formatDate(enrollment['submittedAt']),

                ),

                if (enrollment['guardianFirstName'] != null ||

                    enrollment['guardianLastName'] != null ||

                    enrollment['guardianRelationship'] != null ||

                    enrollment['guardianContactNumber'] != null ||

                    enrollment['guardianAddress'] != null) ...[

                  const SizedBox(height: 12),

                  const Text(

                    'Guardian Information',

                    style: TextStyle(

                      fontSize: 13,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 8),

                  _buildDetailRow(

                    'Guardian First Name',

                    enrollment['guardianFirstName']?.toString() ?? '-',

                  ),

                  _buildDetailRow(

                    'Guardian Last Name',

                    enrollment['guardianLastName']?.toString() ?? '-',

                  ),

                  _buildDetailRow(

                    'Relationship',

                    enrollment['guardianRelationship']?.toString() ?? '-',

                  ),

                  _buildDetailRow(

                    'Contact Number',

                    enrollment['guardianContactNumber']?.toString() ?? '-',

                  ),

                  _buildDetailRow(

                    'Guardian Address',

                    enrollment['guardianAddress']?.toString() ?? '-',

                  ),

                ],

                if (enrollment['adminReviewComment'] != null &&

                    enrollment['adminReviewComment']

                        .toString()

                        .trim()

                        .isNotEmpty) ...[

                  const SizedBox(height: 12),

                  _buildDetailRow(

                    'Review Notes',

                    enrollment['adminReviewComment'].toString(),

                  ),

                ],

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

                          style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.green,

                            foregroundColor: Colors.white,

                          ),

                        ),

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: ElevatedButton.icon(

                          onPressed: () =>

                              _showRejectDialog(context, enrollment),

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

    showDialog(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('Approve Enrollment'),

        content: const Text(

          'Are you sure you want to approve this enrollment?',

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(dialogContext),

            child: const Text('Cancel'),

          ),

          ElevatedButton(

            onPressed: () async {

              final success = await context

                  .read<EnrollmentManagementProvider>()

                  .approveEnrollment(enrollment['id'].toString());



              if (!mounted) return;



              Navigator.pop(dialogContext);



              ScaffoldMessenger.of(context).showSnackBar(

                SnackBar(

                  content: Text(

                    success

                        ? 'Enrollment approved successfully.'

                        : (context

                                .read<EnrollmentManagementProvider>()

                                .errorMessage ??

                            'Failed to approve enrollment.'),

                  ),

                  backgroundColor: success ? Colors.green : Colors.red,

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

                  .read<EnrollmentManagementProvider>()

                  .rejectEnrollment(enrollment['id'].toString(), reason);



              if (!mounted) return;



              Navigator.pop(dialogContext);



              ScaffoldMessenger.of(context).showSnackBar(

                SnackBar(

                  content: Text(

                    success

                        ? 'Enrollment rejected successfully.'

                        : (context

                                .read<EnrollmentManagementProvider>()

                                .errorMessage ??

                            'Failed to reject enrollment.'),

                  ),

                  backgroundColor: success ? Colors.red : Colors.red,

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

