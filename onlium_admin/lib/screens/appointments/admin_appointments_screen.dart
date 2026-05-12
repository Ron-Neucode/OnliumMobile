import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../providers/admin_applications_api_provider.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  bool _isLoading = true;

  String? _errorMessage;

  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();

    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;

      _errorMessage = null;
    });

    try {
      final provider = context.read<AdminApplicationsApiProvider>();

      final data = await provider.fetchAppointments();

      setState(() {
        _appointments = data;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading appointments: $e';

        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appt = _appointments[index];

                    final fullName =
                        '${appt['firstName'] ?? ''} ${appt['lastName'] ?? ''}'
                            .trim();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Unnamed Student' : fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Program: ${appt['programCode'] ?? '-'}'),
                            Text(
                                'Date: ${_formatDate(appt['appointmentDate'])}'),
                            Text('Location: ${appt['location'] ?? '-'}'),
                            Text('Status: ${appt['status'] ?? '-'}'),
                            if ((appt['notes'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty)
                              Text('Notes: ${appt['notes']}'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: (appt['status'] == 'Scheduled')
                                        ? () async {
                                            final success = await context
                                                .read<
                                                    AdminApplicationsApiProvider>()
                                                .confirmPayment(
                                                    appt['id'].toString());

                                            if (!mounted) return;

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? 'Payment confirmed.'
                                                      : (context
                                                              .read<
                                                                  AdminApplicationsApiProvider>()
                                                              .errorMessage ??
                                                          'Failed to confirm payment.'),
                                                ),
                                                backgroundColor: success
                                                    ? Colors.blue
                                                    : Colors.red,
                                              ),
                                            );

                                            if (success) {
                                              await _loadAppointments();
                                            }
                                          }
                                        : null,
                                    child: const Text('Confirm Payment'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        (appt['status'] == 'PaymentConfirmed')
                                            ? () async {
                                                final success = await context
                                                    .read<
                                                        AdminApplicationsApiProvider>()
                                                    .completeEnrollment(
                                                        appt['id'].toString());

                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success
                                                          ? 'Enrollment completed.'
                                                          : (context
                                                                  .read<
                                                                      AdminApplicationsApiProvider>()
                                                                  .errorMessage ??
                                                              'Failed to complete enrollment.'),
                                                    ),
                                                    backgroundColor: success
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                );

                                                if (success) {
                                                  await _loadAppointments();
                                                }
                                              }
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Complete Enrollment'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
