import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../dashboard/appointment_screen.dart';
import '../enrollment/enrollment_screen.dart';
import '../notifications/notification_screen.dart';
import '../study_load/study_load_screen.dart';
import '../resources/resource_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _baseUrl = 'https://localhost:7164';

  int _currentIndex = 0;
  Timer? _refreshTimer;

  bool _isLoadingSummary = true;
  String? _summaryError;

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _bulletins = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _HomeTab(parentState: this),
      const EnrollmentScreen(),
      const StudyLoadScreen(),
      const ResourceScreen(),
      const AppointmentScreen(),
    ]);
    _loadDashboardSummary();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadDashboardSummary();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _summaryError = 'You are not logged in.';
          _isLoadingSummary = false;
        });
        return;
      }

      final notificationsResponse = await http.get(
        Uri.parse('$_baseUrl/api/notifications/mine'),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      final appointmentsResponse = await http.get(
        Uri.parse('$_baseUrl/api/appointments/mine'),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      final applicationsResponse = await http.get(
        Uri.parse('$_baseUrl/api/applications/mine'),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      final bulletinsResponse = await http.get(
        Uri.parse('$_baseUrl/api/Bulletins'),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      List<Map<String, dynamic>> notifications = [];
      List<Map<String, dynamic>> appointments = [];
      List<Map<String, dynamic>> applications = [];
      List<Map<String, dynamic>> bulletins = [];
      String? errorMessage;

      if (notificationsResponse.statusCode == 200) {
        final decoded = jsonDecode(notificationsResponse.body) as List<dynamic>;
        notifications = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (notificationsResponse.statusCode != 401) {
        errorMessage =
            'Notifications failed: ${notificationsResponse.statusCode}';
      }

      if (appointmentsResponse.statusCode == 200) {
        final decoded = jsonDecode(appointmentsResponse.body) as List<dynamic>;
        appointments = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (appointmentsResponse.statusCode != 401) {
        errorMessage = errorMessage == null
            ? 'Appointments failed: ${appointmentsResponse.statusCode}'
            : '$errorMessage • Appointments failed: ${appointmentsResponse.statusCode}';
      }

      if (applicationsResponse.statusCode == 200) {
        final decoded = jsonDecode(applicationsResponse.body) as List<dynamic>;
        applications = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (applicationsResponse.statusCode != 401) {
        errorMessage = errorMessage == null
            ? 'Applications failed: ${applicationsResponse.statusCode}'
            : '$errorMessage • Applications failed: ${applicationsResponse.statusCode}';
      }

      if (bulletinsResponse.statusCode == 200) {
        final decoded = jsonDecode(bulletinsResponse.body) as List<dynamic>;
        bulletins = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (bulletinsResponse.statusCode != 401) {
        errorMessage = errorMessage == null
            ? 'Bulletins failed: ${bulletinsResponse.statusCode}'
            : '$errorMessage • Bulletins failed: ${bulletinsResponse.statusCode}';
      }

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _appointments = appointments;
        _applications = applications;
        _bulletins = bulletins;
        _summaryError = errorMessage;
        _isLoadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _summaryError = 'Error loading dashboard: $e';
        _isLoadingSummary = false;
      });
    }
  }

  int get _unreadNotificationCount =>
      _notifications.where((e) => e['isRead'] != true).length;

  Map<String, dynamic>? get _latestAppointment =>
      _appointments.isNotEmpty ? _appointments.first : null;

  Map<String, dynamic>? get _latestApplication =>
      _applications.isNotEmpty ? _applications.first : null;

  Map<String, dynamic>? get _latestBulletin =>
      _bulletins.isNotEmpty ? _bulletins.first : null;

  bool get _isEnrolled =>
      (_latestApplication?['status']?.toString() ?? '') == 'Completed';

  String get _studentStatusText => _isEnrolled ? 'Enrolled' : 'Not Enrolled';

  String _friendlyApplicationStatus(String? status) {
    switch (status) {
      case 'Draft':
        return 'Draft';
      case 'PendingReview':
        return 'Pending Review';
      case 'Approved':
        return 'Approved';
      case 'Rejected':
        return 'Rejected';
      case 'Completed':
        return 'Enrolled';
      default:
        return status == null || status.isEmpty ? 'No Enrollment Yet' : status;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Scheduled':
        return 'Appointment Scheduled';
      case 'PaymentConfirmed':
        return 'Payment Confirmed';
      case 'Completed':
        return 'Enrollment Completed';
      default:
        return status;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

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

    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '$hour:$minute $period';
  }

  String _shortenText(String text, {int maxLength = 120}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  IconData _notificationTypeIcon(String type) {
    switch (type) {
      case 'Approval':
        return Icons.check_circle;
      case 'Rejection':
        return Icons.cancel;
      case 'Appointment':
        return Icons.event;
      case 'Payment':
        return Icons.payments;
      case 'Enrollment':
        return Icons.school;
      case 'Bulletin':
        return Icons.campaign;
      case 'LMS':
        return Icons.link;
      default:
        return Icons.notifications;
    }
  }

  Color _notificationTypeColor(String type) {
    switch (type) {
      case 'Approval':
        return Colors.green;
      case 'Rejection':
        return Colors.red;
      case 'Appointment':
        return Colors.orange;
      case 'Payment':
        return Colors.blue;
      case 'Enrollment':
        return Colors.teal;
      case 'Bulletin':
        return Colors.indigo;
      case 'LMS':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<_RecentActivityItem> _buildRecentActivities() {
    final items = <_RecentActivityItem>[];

    if (_latestApplication != null) {
      items.add(
        _RecentActivityItem(
          title: 'Enrollment Status',
          subtitle: _friendlyApplicationStatus(
            _latestApplication!['status']?.toString(),
          ),
          trailingText: _formatDate(
            _latestApplication!['submittedAt'] ??
                _latestApplication!['createdAt'],
          ),
          icon: _isEnrolled ? Icons.school : Icons.assignment,
          iconColor: _isEnrolled ? Colors.green : Colors.blue,
        ),
      );
    }

    if (_latestAppointment != null) {
      final status = _latestAppointment!['status']?.toString() ?? 'Scheduled';

      items.add(
        _RecentActivityItem(
          title: _statusLabel(status),
          subtitle:
              'Appointment on ${_formatDate(_latestAppointment!['appointmentDate'])}',
          trailingText:
              _latestAppointment!['location']?.toString() ?? 'School Campus',
          icon: Icons.event_available,
          iconColor: status == 'Completed'
              ? Colors.green
              : status == 'PaymentConfirmed'
              ? Colors.blue
              : Colors.orange,
        ),
      );
    }

    if (_latestBulletin != null) {
      items.add(
        _RecentActivityItem(
          title: _latestBulletin!['title']?.toString() ?? 'Bulletin',
          subtitle: _shortenText(
            _latestBulletin!['content']?.toString() ?? '',
            maxLength: 80,
          ),
          trailingText: _formatDate(_latestBulletin!['createdAt']),
          icon: Icons.campaign,
          iconColor: Colors.indigo,
        ),
      );
    }

    for (final notification in _notifications.take(2)) {
      final type = notification['notificationType']?.toString() ?? 'General';

      items.add(
        _RecentActivityItem(
          title: notification['title']?.toString() ?? 'Notification',
          subtitle: notification['message']?.toString() ?? '',
          trailingText: _formatDate(notification['createdAt']),
          icon: _notificationTypeIcon(type),
          iconColor: _notificationTypeColor(type),
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _RecentActivityItem(
          title: 'Logged in successfully',
          subtitle: 'Your student dashboard is ready to use.',
          trailingText: 'Just now',
          icon: Icons.login,
          iconColor: Colors.green,
        ),
      );
    }

    return items;
  }

  void _showBulletinsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 520,
          child: Column(
            children: [
              AppBar(
                title: const Text('Bulletin Board'),
                automaticallyImplyLeading: false,
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: _bulletins.isEmpty
                    ? const Center(
                        child: Text(
                          'No bulletins available yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _bulletins.length,
                        itemBuilder: (context, index) {
                          final bulletin = _bulletins[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bulletin['title']?.toString() ?? 'Untitled',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bulletin['content']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Posted: ${_formatDate(bulletin['createdAt'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1E63B6),
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Students',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                activeIcon: Icon(Icons.article),
                label: 'Resources',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthProvider authProvider) {
    return Row(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          color: Colors.white,
          onSelected: (value) async {
            if (value == 'edit_profile') {
              _showEditProfileDialog(context, authProvider);
            } else if (value == 'logout') {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'edit_profile',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF1E63B6)),
                  SizedBox(width: 12),
                  Text('Edit Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Log Out', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(Icons.school, color: Color(0xFF1E4A8A), size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Edit profile functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountHeader(AuthProvider authProvider) {
    final fullName = authProvider.fullName?.isNotEmpty == true
        ? authProvider.fullName!
        : 'Student';

    final applicationStatus = _friendlyApplicationStatus(
      _latestApplication?['status']?.toString(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1E63B6).withOpacity(0.12),
            child: const Icon(Icons.person, color: Color(0xFF1E63B6), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E4A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Student Status: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _isEnrolled
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _studentStatusText,
                        style: TextStyle(
                          color: _isEnrolled
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enrollment Progress: $applicationStatus',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  authProvider.email ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(BuildContext context) {
    final bannerText = _isLoadingSummary
        ? 'Loading your latest updates...'
        : _unreadNotificationCount > 0
        ? 'You have $_unreadNotificationCount new notification${_unreadNotificationCount == 1 ? '' : 's'} including enrollment updates and important announcements.'
        : 'You have no new notifications right now.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E9D8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bannerText,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFFB36A19),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, color: Color(0xFFB36A19)),
              label: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFFB36A19),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinCard() {
    final latestTitle = _latestBulletin?['title']?.toString();
    final latestContent = _latestBulletin?['content']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign, color: Color(0xFF2A68B8), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Bulletin Board',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A68B8),
                        ),
                      ),
                    ),
                    if (_latestBulletin != null) const _NewBadge(),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isLoadingSummary)
                  const Text(
                    'Loading latest bulletin...',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF2A68B8),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (_latestBulletin == null)
                  const Text(
                    'No bulletin announcements available yet.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF2A68B8),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else ...[
                  Text(
                    latestTitle ?? 'Latest Bulletin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A68B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shortenText(latestContent ?? '', maxLength: 160),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF2A68B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showBulletinsDialog,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF2A68B8),
                      ),
                      label: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF2A68B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_summaryError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _summaryError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<_RecentActivityItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: item.iconColor.withOpacity(0.12),
                    child: Icon(item.icon, color: item.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.trailingText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index != items.length - 1) ...[
                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 14),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[700],
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE64A4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final _DashboardScreenState parentState;

  const _HomeTab({required this.parentState});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    final parent = widget.parentState;
    final authProvider = context.watch<AuthProvider>();
    final recentActivities = parent._buildRecentActivities();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E63B6),
            Color(0xFF5F97D8),
            Color(0xFF9CC8F5),
            Color(0xFFD6ECFF),
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: parent._loadDashboardSummary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              parent._buildTopBar(context, authProvider),
              const SizedBox(height: 14),
              parent._buildAccountHeader(authProvider),
              const SizedBox(height: 14),
              parent._buildNotificationBanner(context),
              const SizedBox(height: 14),
              parent._buildBulletinCard(),
              const SizedBox(height: 24),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              parent._buildRecentActivityCard(recentActivities),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityItem {
  final String title;
  final String subtitle;
  final String trailingText;
  final IconData icon;
  final Color iconColor;

  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.icon,
    required this.iconColor,
  });
}
