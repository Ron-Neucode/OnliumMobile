import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin.dart';
import '../../providers/admin_applications_api_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/admin_bulletins_api_provider.dart';
import '../../providers/admin_resources_api_provider.dart';
import '../../providers/admin_studyloads_api_provider.dart';
import '../appointments/admin_appointments_screen.dart';
import '../auth/admin_login_screen.dart';
import '../enrollments/admin_enrollment_api_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AdminAuthProvider>();
    final admin = authProvider.currentAdmin!;

    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/logos.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, color: Colors.white, size: 32),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${admin.fullName}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Role: ${_getRoleDisplay(admin.role)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.logout();
                        if (!context.mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AdminLoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Management Tabs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.4,
                children: [
                  _buildTabCard(
                    context,
                    title: 'Student Management',
                    icon: Icons.people,
                    color: Colors.blue[600]!,
                    onTap: () => _showTabScreen(context, 0),
                  ),
                  _buildTabCard(
                    context,
                    title: 'Course/Curriculum Management',
                    icon: Icons.school,
                    color: Colors.purple[600]!,
                    onTap: () => _showTabScreen(context, 1),
                  ),
                  _buildTabCard(
                    context,
                    title: 'Resource',
                    icon: Icons.library_books,
                    color: Colors.teal[600]!,
                    onTap: () => _showTabScreen(context, 2),
                  ),
                  _buildTabCard(
                    context,
                    title: 'Bulletin',
                    icon: Icons.campaign,
                    color: Colors.amber[600]!,
                    onTap: () => _showTabScreen(context, 3),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminEnrollmentApiScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment),
                      label: const Text('Manage Enrollments'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminAppointmentsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Manage Appointments'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getRoleDisplay(AdminRole role) {
    switch (role) {
      case AdminRole.administrator:
        return 'Administrator';
    }
  }

  Widget _buildTabCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTabScreen(BuildContext context, int tabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _TabScreen(
          title: _getTabTitle(tabIndex),
          tabIndex: tabIndex,
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Student Management';
      case 1:
        return 'Course/Curriculum Management';
      case 2:
        return 'Resource';
      case 3:
        return 'Bulletin';
      default:
        return 'Unknown';
    }
  }
}

class _TabScreen extends StatefulWidget {
  final String title;
  final int tabIndex;

  const _TabScreen({
    required this.title,
    required this.tabIndex,
  });

  @override
  State<_TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<_TabScreen> {
  final List<Map<String, dynamic>> _studentApplications = [];

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildTabContent(widget.tabIndex),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildStudentManagementContent();
      case 1:
        return _buildCourseCurriculumContent();
      case 2:
        return _buildResourceContent();
      case 3:
        return _buildBulletinContent();
      default:
        return const Center(child: Text('Tab not implemented'));
    }
  }

  Widget _buildStudentManagementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              title: 'View All Students',
              icon: Icons.people,
              color: Colors.blue[600]!,
              onTap: () => _showAllStudentsDialog(context),
            ),
            _buildActionCard(
              title: 'View Student Applications',
              icon: Icons.pending_actions,
              color: Colors.orange[600]!,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminEnrollmentApiScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseCurriculumContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course/Curriculum Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              title: 'Assign Courses',
              icon: Icons.assignment,
              color: Colors.orange[600]!,
              onTap: () => _showAssignCoursesDialog(context),
            ),
            _buildActionCard(
              title: 'View Study Loads',
              icon: Icons.book,
              color: Colors.blue[600]!,
              onTap: () => _showViewStudyLoadsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resource Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              title: 'Send Exam Link',
              icon: Icons.link,
              color: Colors.blue[600]!,
              onTap: () => _showSendResourceDialog(context, 'Exam'),
            ),
            _buildActionCard(
              title: 'Send Quiz Link',
              icon: Icons.quiz,
              color: Colors.green[600]!,
              onTap: () => _showSendResourceDialog(context, 'Quiz'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBulletinContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bulletin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              title: 'Post Announcement',
              icon: Icons.post_add,
              color: Colors.red[600]!,
              onTap: () => _showPostAnnouncementDialog(context),
            ),
            _buildActionCard(
              title: 'Manage Posts',
              icon: Icons.manage_search,
              color: Colors.blue[600]!,
              onTap: () => _showManagePostsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectApplicationDialog(
    BuildContext context,
    String applicationId,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
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
              if (reason.isEmpty) return;

              final provider = context.read<AdminApplicationsApiProvider>();
              final success = await provider.rejectEnrollment(
                applicationId,
                reason,
              );

              if (!context.mounted) return;

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Application rejected.'
                        : (provider.errorMessage ?? 'Reject failed.'),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyLoadSummaryBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStudyLoadSubjectCard(Map<String, dynamic> item) {
    final subjectCode = item['subjectCode']?.toString() ?? '-';
    final subjectTitle = item['subjectTitle']?.toString() ?? '-';
    final lecUnits = item['lecUnits']?.toString() ?? '0';
    final labUnits = item['labUnits']?.toString() ?? '0';
    final totalUnits = item['totalUnits']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.book, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subjectTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalUnits units',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.class_, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Lecture Units: $lecUnits',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.science, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Laboratory Units: $labUnits',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showViewStudyLoadsDialog(BuildContext context) {
    String selectedProgram = 'BSIT';
    int selectedYearLevel = 1;
    int selectedSemester = 1;
    bool hasLoadedInitially = false;
    final ScrollController scrollController = ScrollController();

    Future<void> loadStudyLoads() async {
      await context.read<AdminStudyLoadsApiProvider>().fetchStudyLoads(
            programCode: selectedProgram,
            yearLevel: selectedYearLevel,
            semester: selectedSemester,
          );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!hasLoadedInitially) {
              hasLoadedInitially = true;
              Future.microtask(() async {
                await loadStudyLoads();
                if (context.mounted) {
                  setDialogState(() {});
                }
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenSize.width * 0.92,
                  maxHeight: screenSize.height * 0.82,
                ),
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Consumer<AdminStudyLoadsApiProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'View Study Loads',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: selectedProgram,
                                    decoration: const InputDecoration(
                                      labelText: 'Program Code',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'BSIT',
                                        child: Text('BSIT'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'BSCS',
                                        child: Text('BSCS'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'BSBA',
                                        child: Text('BSBA'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'BSA',
                                        child: Text('BSA'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'BSHM',
                                        child: Text('BSHM'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(() {
                                        selectedProgram = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int>(
                                    value: selectedYearLevel,
                                    decoration: const InputDecoration(
                                      labelText: 'Year Level',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text('1st Year'),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text('2nd Year'),
                                      ),
                                      DropdownMenuItem(
                                        value: 3,
                                        child: Text('3rd Year'),
                                      ),
                                      DropdownMenuItem(
                                        value: 4,
                                        child: Text('4th Year'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(() {
                                        selectedYearLevel = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int>(
                                    value: selectedSemester,
                                    decoration: const InputDecoration(
                                      labelText: 'Semester',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text('1st Semester'),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text('2nd Semester'),
                                      ),
                                      DropdownMenuItem(
                                        value: 3,
                                        child: Text('Summer'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(() {
                                        selectedSemester = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await loadStudyLoads();
                                        if (context.mounted) {
                                          setDialogState(() {});
                                        }
                                      },
                                      icon: const Icon(Icons.search),
                                      label: const Text('Load Study Load'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStudyLoadSummaryBox(
                                    title: 'Program',
                                    value: selectedProgram,
                                    color: Colors.blue,
                                    icon: Icons.school,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStudyLoadSummaryBox(
                                    title: 'Year',
                                    value: '$selectedYearLevel',
                                    color: Colors.orange,
                                    icon: Icons.badge,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStudyLoadSummaryBox(
                                    title: 'Semester',
                                    value: '$selectedSemester',
                                    color: Colors.green,
                                    icon: Icons.calendar_today,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Subjects',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (provider.isLoading)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (provider.errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  provider.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            else if (provider.studyLoads.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 42,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No study load subjects found.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'There are no subjects yet for the selected program, year level, and semester.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.studyLoads.length,
                                itemBuilder: (context, index) {
                                  final item = provider.studyLoads[index];
                                  return _buildAdminStudyLoadSubjectCard(item);
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSendResourceDialog(BuildContext context, String resourceType) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Send $resourceType Link'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '$resourceType Title',
                  hintText: 'Enter the $resourceType title',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: '$resourceType Link',
                  hintText: 'Enter the $resourceType link',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Consumer<AdminResourcesApiProvider>(
            builder: (context, resourceProvider, child) {
              return ElevatedButton(
                onPressed: resourceProvider.isLoading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        final url = urlController.text.trim();

                        if (title.isEmpty || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please fill in both title and link.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final success = await context
                            .read<AdminResourcesApiProvider>()
                            .createResource(
                              resourceType: resourceType,
                              title: title,
                              url: url,
                            );

                        if (!context.mounted) return;

                        Navigator.pop(dialogContext);

                        final provider =
                            context.read<AdminResourcesApiProvider>();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '$resourceType link sent successfully.'
                                  : (provider.errorMessage ??
                                      'Failed to send $resourceType link.'),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                child: resourceProvider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAssignCoursesDialog(BuildContext context) {
    final programController = TextEditingController(text: 'BSIT');
    final subjectCodeController = TextEditingController();
    final subjectTitleController = TextEditingController();
    final lecUnitsController = TextEditingController(text: '3');
    final labUnitsController = TextEditingController(text: '0');

    int selectedYearLevel = 1;
    int selectedSemester = 1;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Courses & Units'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: programController,
                      decoration: const InputDecoration(
                        labelText: 'Program Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedYearLevel,
                      decoration: const InputDecoration(
                        labelText: 'Year Level',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1st Year')),
                        DropdownMenuItem(value: 2, child: Text('2nd Year')),
                        DropdownMenuItem(value: 3, child: Text('3rd Year')),
                        DropdownMenuItem(value: 4, child: Text('4th Year')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedYearLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1st Semester')),
                        DropdownMenuItem(value: 2, child: Text('2nd Semester')),
                        DropdownMenuItem(value: 3, child: Text('Summer')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedSemester = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lecUnitsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Lecture Units',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labUnitsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Laboratory Units',
                        border: OutlineInputBorder(),
                      ),
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
              Consumer<AdminStudyLoadsApiProvider>(
                builder: (context, studyLoadProvider, child) {
                  return ElevatedButton(
                    onPressed: studyLoadProvider.isLoading
                        ? null
                        : () async {
                            final programCode = programController.text.trim();
                            final subjectCode =
                                subjectCodeController.text.trim();
                            final subjectTitle =
                                subjectTitleController.text.trim();
                            final lecUnits =
                                double.tryParse(lecUnitsController.text.trim());
                            final labUnits =
                                double.tryParse(labUnitsController.text.trim());

                            if (programCode.isEmpty ||
                                subjectCode.isEmpty ||
                                subjectTitle.isEmpty ||
                                lecUnits == null ||
                                labUnits == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please complete all fields.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final success = await context
                                .read<AdminStudyLoadsApiProvider>()
                                .createStudyLoad(
                                  programCode: programCode,
                                  yearLevel: selectedYearLevel,
                                  semester: selectedSemester,
                                  subjectCode: subjectCode,
                                  subjectTitle: subjectTitle,
                                  lecUnits: lecUnits,
                                  labUnits: labUnits,
                                );

                            if (!context.mounted) return;

                            Navigator.pop(dialogContext);

                            final provider =
                                context.read<AdminStudyLoadsApiProvider>();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Study load subject added successfully.'
                                      : (provider.errorMessage ??
                                          'Failed to add study load subject.'),
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          },
                    child: studyLoadProvider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatBulletinDate(dynamic value) {
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

  void _showPostAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Post Announcement'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'Enter announcement title',
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  hintText: 'Enter announcement message',
                ),
                maxLines: 5,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Consumer<AdminBulletinsApiProvider>(
            builder: (context, bulletinProvider, child) {
              return ElevatedButton(
                onPressed: bulletinProvider.isLoading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        final content = messageController.text.trim();

                        if (title.isEmpty || content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please fill in both title and message'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final success = await context
                            .read<AdminBulletinsApiProvider>()
                            .createBulletin(
                              title: title,
                              content: content,
                            );

                        if (!context.mounted) return;

                        Navigator.pop(dialogContext);

                        final provider =
                            context.read<AdminBulletinsApiProvider>();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Bulletin posted successfully.'
                                  : (provider.errorMessage ??
                                      'Failed to post bulletin.'),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: bulletinProvider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showManagePostsDialog(BuildContext context) {
    final provider = context.read<AdminBulletinsApiProvider>();
    provider.fetchBulletins();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Consumer<AdminBulletinsApiProvider>(
            builder: (context, bulletinProvider, child) {
              if (bulletinProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (bulletinProvider.errorMessage != null) {
                return Center(
                  child: Text(
                    bulletinProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (bulletinProvider.bulletins.isEmpty) {
                return const Center(
                  child: Text(
                    'No bulletins posted yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  AppBar(
                    title: const Text('Manage Posts'),
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
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: bulletinProvider.bulletins.length,
                      itemBuilder: (context, index) {
                        final bulletin = bulletinProvider.bulletins[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              bulletin['title']?.toString() ?? 'Untitled',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${bulletin['content'] ?? ''}\n\nPosted: ${_formatBulletinDate(bulletin['createdAt'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _editAnnouncement(context, bulletin),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _deleteAnnouncement(context, bulletin),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _editAnnouncement(
    BuildContext context,
    Map<String, dynamic> bulletin,
  ) {
    final titleController =
        TextEditingController(text: bulletin['title']?.toString() ?? '');
    final messageController =
        TextEditingController(text: bulletin['content']?.toString() ?? '');
    bool isPublished = bulletin['isPublished'] == true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Announcement'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published'),
                    value: isPublished,
                    onChanged: (value) {
                      setDialogState(() {
                        isPublished = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              Consumer<AdminBulletinsApiProvider>(
                builder: (context, bulletinProvider, child) {
                  return ElevatedButton(
                    onPressed: bulletinProvider.isLoading
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final content = messageController.text.trim();

                            if (title.isEmpty || content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please fill in both title and message'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final success = await context
                                .read<AdminBulletinsApiProvider>()
                                .updateBulletin(
                                  id: bulletin['id'].toString(),
                                  title: title,
                                  content: content,
                                  isPublished: isPublished,
                                );

                            if (!context.mounted) return;

                            Navigator.pop(dialogContext);

                            final provider =
                                context.read<AdminBulletinsApiProvider>();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Bulletin updated successfully.'
                                      : (provider.errorMessage ??
                                          'Failed to update bulletin.'),
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          },
                    child: bulletinProvider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteAnnouncement(
    BuildContext context,
    Map<String, dynamic> bulletin,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
          'Are you sure you want to delete this announcement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Consumer<AdminBulletinsApiProvider>(
            builder: (context, bulletinProvider, child) {
              return ElevatedButton(
                onPressed: bulletinProvider.isLoading
                    ? null
                    : () async {
                        final success = await context
                            .read<AdminBulletinsApiProvider>()
                            .deleteBulletin(bulletin['id'].toString());

                        if (!context.mounted) return;

                        Navigator.pop(dialogContext);

                        final provider =
                            context.read<AdminBulletinsApiProvider>();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Bulletin deleted successfully.'
                                  : (provider.errorMessage ??
                                      'Failed to delete bulletin.'),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                ),
                child: bulletinProvider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAllStudentsDialog(BuildContext context) {
    String selectedGender = 'All';
    String selectedYearLevel = 'All';
    String selectedProgram = 'All';
    String selectedStudentType = 'All';

    List<Map<String, dynamic>> students = [];
    bool isLoading = true;
    String? errorMessage;

    Future<void> loadStudents(StateSetter setDialogState) async {
      setDialogState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final provider = context.read<AdminApplicationsApiProvider>();

        final result = await provider.fetchCompletedStudents(
          yearLevel: selectedYearLevel == 'All'
              ? null
              : int.tryParse(
                  selectedYearLevel.replaceAll(RegExp(r'[^0-9]'), ''),
                ),
          programCode: selectedProgram == 'All' ? null : selectedProgram,
          gender: selectedGender == 'All' ? null : selectedGender,
          studentType:
              selectedStudentType == 'All' ? null : selectedStudentType,
        );

        setDialogState(() {
          students = result;
          isLoading = false;
        });
      } catch (e) {
        setDialogState(() {
          errorMessage = 'Error loading students: $e';
          isLoading = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoading && students.isEmpty && errorMessage == null) {
            Future.microtask(() => loadStudents(setDialogState));
          }

          return AlertDialog(
            title: const Text('All Enrolled Students'),
            content: SizedBox(
              width: double.maxFinite,
              height: 520,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedGender,
                                isExpanded: true,
                                items: ['All', 'Male', 'Female']
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  setDialogState(() {
                                    selectedGender = value!;
                                  });
                                  await loadStudents(setDialogState);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedYearLevel,
                                isExpanded: true,
                                items: [
                                  'All',
                                  '1st Year',
                                  '2nd Year',
                                  '3rd Year',
                                  '4th Year',
                                ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  setDialogState(() {
                                    selectedYearLevel = value!;
                                  });
                                  await loadStudents(setDialogState);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedProgram,
                                isExpanded: true,
                                items: [
                                  'All',
                                  'BSIT',
                                  'BSCS',
                                  'BSBA',
                                  'BSA',
                                  'BSHM'
                                ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  setDialogState(() {
                                    selectedProgram = value!;
                                  });
                                  await loadStudents(setDialogState);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedStudentType,
                                isExpanded: true,
                                items: [
                                  'All',
                                  'NewIncoming',
                                  'Transferee',
                                  'Continuing',
                                ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          value == 'NewIncoming'
                                              ? 'New/Incoming'
                                              : value,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  setDialogState(() {
                                    selectedStudentType = value!;
                                  });
                                  await loadStudents(setDialogState);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null
                            ? Center(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : students.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No enrolled students found.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: students.length,
                                    itemBuilder: (context, index) {
                                      final student = students[index];
                                      final fullName =
                                          student['fullName']?.toString() ??
                                              'Unnamed Student';

                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue[600],
                                            child: Text(
                                              fullName
                                                  .split(' ')
                                                  .where((x) => x.isNotEmpty)
                                                  .take(2)
                                                  .map((x) => x[0])
                                                  .join()
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Program: ${student['programCode'] ?? '-'}',
                                              ),
                                              Text(
                                                'Year Level: ${student['yearLevel'] ?? '-'}',
                                              ),
                                              Text(
                                                'Gender: ${student['gender'] ?? '-'}',
                                              ),
                                              Text(
                                                'Type: ${student['studentType'] == 'NewIncoming' ? 'New/Incoming' : student['studentType'] ?? '-'}',
                                              ),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.info,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _showStudentInfoDialog(
                                              context,
                                              student,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStudentApplicationsDialog(BuildContext context) {
    final provider = context.read<AdminApplicationsApiProvider>();
    provider.fetchPendingEnrollments();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Consumer<AdminApplicationsApiProvider>(
            builder: (context, apiProvider, child) {
              final applications = apiProvider.pendingEnrollments;

              if (apiProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (applications.isEmpty) {
                return const Center(
                  child: Text(
                    'No pending student applications.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  AppBar(
                    title: const Text('Student Applications'),
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: applications.length,
                      itemBuilder: (context, index) {
                        final application = applications[index];

                        final firstName =
                            application['firstName']?.toString() ?? '';
                        final lastName =
                            application['lastName']?.toString() ?? '';
                        final fullName = '$firstName $lastName'.trim().isEmpty
                            ? 'Unnamed Student'
                            : '$firstName $lastName'.trim();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Student Type: ${application['studentType'] ?? '-'}',
                                ),
                                Text(
                                  'Program: ${application['programCode'] ?? '-'}',
                                ),
                                Text(
                                  'Year Level: ${application['yearLevel'] ?? '-'}',
                                ),
                                Text(
                                  'Submitted: ${application['submittedAt'] ?? '-'}',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final success = await apiProvider
                                              .approveEnrollment(
                                            application['id'].toString(),
                                          );

                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success
                                                    ? 'Application approved.'
                                                    : (apiProvider
                                                            .errorMessage ??
                                                        'Approve failed.'),
                                              ),
                                              backgroundColor: success
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showRejectApplicationDialog(
                                            context,
                                            application['id'].toString(),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Reject'),
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showStudentInfoDialog(
    BuildContext context,
    Map<String, dynamic> student,
  ) {
    final fullName = student['fullName']?.toString() ?? 'Unnamed Student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Information'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[600],
                    child: Text(
                      fullName
                          .split(' ')
                          .where((x) => x.isNotEmpty)
                          .take(2)
                          .map((x) => x[0])
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Application ID: ${student['id']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student['status']?.toString() ?? 'Completed',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                'Email',
                student['email']?.toString() ?? '-',
                Icons.email,
              ),
              _buildInfoRow(
                'Phone',
                student['phoneNumber']?.toString() ?? '-',
                Icons.phone,
              ),
              _buildInfoRow(
                'Address',
                student['address']?.toString() ?? '-',
                Icons.location_on,
              ),
              _buildInfoRow(
                'Gender',
                student['gender']?.toString() ?? '-',
                Icons.person,
              ),
              _buildInfoRow(
                'Year Level',
                student['yearLevel']?.toString() ?? '-',
                Icons.school,
              ),
              _buildInfoRow(
                'Program',
                student['programCode']?.toString() ?? '-',
                Icons.business,
              ),
              _buildInfoRow(
                'Student Type',
                student['studentType'] == 'NewIncoming'
                    ? 'New/Incoming'
                    : student['studentType']?.toString() ?? '-',
                Icons.badge,
              ),
              _buildInfoRow(
                'Birth Date',
                student['birthDate']?.toString().split('T').first ?? '-',
                Icons.calendar_today,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 12,
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
}
