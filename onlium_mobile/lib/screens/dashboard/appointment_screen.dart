import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../enrollment/enrollment_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _appointments = [];
          _errorMessage = 'Your session has expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Appointments/mine'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          _appointments = List<Map<String, dynamic>>.from(decoded);
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 401) {
        setState(() {
          _appointments = [];
          _errorMessage = 'Your session has expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final serverMessage = _extractMessage(response.body);

      setState(() {
        _appointments = [];
        _errorMessage =
            serverMessage ??
            'Failed to load appointments. Status: ${response.statusCode}.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _appointments = [];
        _errorMessage = 'Unable to connect to the server: $e';
        _isLoading = false;
      });
    }
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get _latestAppointment {
    if (_appointments.isEmpty) return null;

    final sorted = [..._appointments];

    sorted.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['appointmentDate']?.toString() ?? '') ??
          DateTime(1900);

      final bDate =
          DateTime.tryParse(b['appointmentDate']?.toString() ?? '') ??
          DateTime(1900);

      return bDate.compareTo(aDate);
    });

    return sorted.first;
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return 'Appointment Scheduled';
      case 'paymentconfirmed':
      case 'payment confirmed':
        return 'Payment Confirmed';
      case 'completed':
        return 'Enrollment Completed';
      case 'cancelled':
        return 'Appointment Cancelled';
      default:
        return status.isEmpty ? 'Unknown Status' : status;
    }
  }

  String _statusMessage(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return 'Please proceed to the school on your scheduled appointment date and pay your required downpayment for this semester.';
      case 'paymentconfirmed':
      case 'payment confirmed':
        return 'Your payment has been confirmed. Please wait while your enrollment is being finalized.';
      case 'completed':
        return 'You are now officially enrolled. Your study load can now be released.';
      case 'cancelled':
        return 'Your appointment has been cancelled. Please wait for further instructions or contact the administrator.';
      default:
        return 'Please wait for further instructions from the administrator.';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return Colors.orange;
      case 'paymentconfirmed':
      case 'payment confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'scheduled':
        return Icons.event_available_rounded;
      case 'paymentconfirmed':
      case 'payment confirmed':
        return Icons.payments_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'Not scheduled';

    final raw = value.toString();
    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return raw;

    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;

    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');

    return '${parsed.year}-$month-$day $hour:$minute $period';
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final authProvider = context.watch<AuthProvider>();
    final fullName = authProvider.fullName ?? '';
    final email = authProvider.email ?? '';
    final latestAppointment = _latestAppointment;

    final status = latestAppointment?['status']?.toString() ?? '';
    final hasAppointment = latestAppointment != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: hasAppointment
                    ? _statusColor(status)
                    : Colors.blue[700],
                child: Icon(
                  hasAppointment
                      ? _statusIcon(status)
                      : Icons.event_note_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAppointment
                          ? _statusLabel(status)
                          : 'No Appointment Yet',
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasAppointment
                          ? 'Your appointment details are available below.'
                          : 'Your appointment will appear here once scheduled by the administrator.',
                      style: const TextStyle(
                        color: Color(0xFF627D98),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Signed in as',
            value: fullName.isNotEmpty ? fullName : 'Student',
          ),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email.isNotEmpty ? email : 'Not available',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 58, color: Colors.orange[700]),
          const SizedBox(height: 14),
          const Text(
            'No Appointment Scheduled Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102A43),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your appointment will appear here after the administrator approves your application and schedules your visit to school.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF334E68),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EnrollmentScreen()),
                );
              },
              icon: const Icon(Icons.assignment_rounded),
              label: const Text('Go to Enrollment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 58, color: Colors.red[600]),
          const SizedBox(height: 14),
          const Text(
            'Unable to Load Appointment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status']?.toString() ?? 'Scheduled';
    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(_statusIcon(status), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date and Time',
            value: _formatDateTime(appointment['appointmentDate']),
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: appointment['location']?.toString() ?? 'School Campus',
          ),
          _buildInfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Status',
            value: _statusLabel(status),
          ),
          _buildInfoRow(
            icon: Icons.notes_rounded,
            label: 'Notes',
            value:
                appointment['notes']?.toString() ??
                'Please proceed to the school to complete your enrollment.',
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(
              _statusMessage(status),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorCard();
    }

    if (_appointments.isEmpty) {
      return _buildEmptyAppointmentCard();
    }

    return Column(
      children: _appointments.map((appointment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAppointmentCard(appointment),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Appointment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
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
          child: RefreshIndicator(
            onRefresh: _loadAppointments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight + 24,
                16,
                24,
              ),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildBodyContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
