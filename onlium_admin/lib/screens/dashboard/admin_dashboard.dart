import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/enrollment_management_provider.dart';
import '../auth/admin_login_screen.dart';
import '../enrollments/enrollment_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final enrollmentProvider =
        Provider.of<EnrollmentManagementProvider>(context);
    final admin = authProvider.currentAdmin!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3F7ED8),
            const Color(0xFF8EC7FF),
            const Color(0xFFD6ECFF),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blue[700],
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
              // Welcome Card
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
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                    fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await authProvider.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminLoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
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
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Management Tabs
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

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const EnrollmentManagementScreen(),
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

  Widget _buildMetricCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _getRoleDisplay(AdminRole role) {
    switch (role) {
      case AdminRole.administrator:
        return 'Administrator';
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

class _TabScreenState extends State<_TabScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _courses = [];
  final List<Map<String, dynamic>> _enrolledStudents = [];
  final List<Map<String, dynamic>> _studentApplications = [];
  final List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    // No TabController needed since Notification and Bulletin are now separate tabs
  }

  @override
  void dispose() {
    // No TabController to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3F7ED8),
            const Color(0xFF8EC7FF),
            const Color(0xFFD6ECFF),
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
      case 0: // Student Management
        return _buildStudentManagementContent();
      case 1: // Course/Curriculum Management
        return _buildCourseCurriculumContent();
      case 2: // Resource
        return _buildResourceContent();
      case 3: // Bulletin
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
              onTap: () => _showStudentApplicationsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showViewStudyLoadsDialog(BuildContext context) {
    String selectedProgramId = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Map<String, dynamic>? selectedProgram;
          if (selectedProgramId.isNotEmpty) {
            try {
              selectedProgram = _courses
                  .firstWhere((course) => course['id'] == selectedProgramId);
            } catch (e) {
              selectedProgram = null;
            }
          }

          final curriculum = selectedProgram != null
              ? selectedProgram['curriculum'] as Map<String, dynamic>
              : <String, dynamic>{};

          if (_courses.isEmpty) {
            return AlertDialog(
              title: const Text('View Study Loads'),
              content: const SizedBox(
                width: double.maxFinite,
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Programs Available',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Programs data will be loaded from the backend.\nPlease ensure the backend API is connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
          }

          return AlertDialog(
            title: const Text('View Study Loads'),
            content: SizedBox(
              width: double.maxFinite,
              height: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedProgramId.isEmpty ? null : selectedProgramId,
                    decoration: const InputDecoration(
                      labelText: 'Select Program',
                      border: OutlineInputBorder(),
                    ),
                    items: _courses.map((program) {
                      return DropdownMenuItem<String>(
                        value: program['id'] as String,
                        child: Text('${program['code']} - ${program['title']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProgramId = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: selectedProgram == null
                        ? const Center(
                            child: Text(
                                'Choose a program to view its full study load.'),
                          )
                        : ListView(
                            children: [
                              Text(
                                '${selectedProgram['code']} - ${selectedProgram['title']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final year in [
                                '1st Year',
                                '2nd Year',
                                '3rd Year',
                                '4th Year'
                              ])
                                if (curriculum.containsKey(year)) ...[
                                  Text(
                                    year,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final semester in [
                                    '1st Semester',
                                    '2nd Semester'
                                  ])
                                    if ((curriculum[year]
                                            as Map<String, dynamic>)
                                        .containsKey(semester)) ...[
                                      Text(
                                        semester,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...((curriculum[year][semester] as List)
                                          .map((course) {
                                        final courseMap =
                                            course as Map<String, dynamic>;
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text(
                                                '${courseMap['code']}: ${courseMap['name']}'),
                                            subtitle: Text(
                                              'Lec ${courseMap['lecUnits']} | Lab ${courseMap['labUnits']} | Total ${courseMap['totalUnits']}\nPrerequisites: ${((courseMap['prerequisites'] as List).isEmpty ? 'None' : (courseMap['prerequisites'] as List).join(', '))}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            isThreeLine: true,
                                          ),
                                        );
                                      }).cast<Widget>()),
                                      const SizedBox(height: 12),
                                    ],
                                ],
                            ],
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

  void _showSendExamLinkDialog(BuildContext context) {
    String examLink = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Exam Link'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Exam Link',
            hintText: 'Enter the exam link to send to students',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            examLink = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (examLink.isNotEmpty) {
                // Here you would implement the logic to send the link to students
                // For now, just show a snackbar
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exam link sent to students: $examLink'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSendQuizLinkDialog(BuildContext context) {
    String quizLink = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quiz Link'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Quiz Link',
            hintText: 'Enter the quiz link to send to students',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            quizLink = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (quizLink.isNotEmpty) {
                // Here you would implement the logic to send the link to students
                // For now, just show a snackbar
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quiz link sent to students: $quizLink'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
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
              onTap: () => _showSendExamLinkDialog(context),
            ),
            _buildActionCard(
              title: 'Send Quiz Link',
              icon: Icons.quiz,
              color: Colors.green[600]!,
              onTap: () => _showSendQuizLinkDialog(context),
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
                onTap: () => _showViewStudyLoadsDialog(context)),
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

  void _showPostAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in both title and message'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() {
                _announcements.add({
                  'title': titleController.text.trim(),
                  'message': messageController.text.trim(),
                  'date': DateTime.now().toString().split('.')[0],
                });
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Announcement "${titleController.text.length > 20 ? titleController.text.substring(0, 20) + "..." : titleController.text}" posted to all students!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showManagePostsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Posts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _announcements.isEmpty
              ? const Center(
                  child: Text(
                    'No announcements posted yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = _announcements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          announcement['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${announcement['message']}\n\nPosted: ${announcement['date']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _editAnnouncement(context, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteAnnouncement(context, index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  void _editAnnouncement(BuildContext context, int index) {
    final announcement = _announcements[index];
    final titleController = TextEditingController(text: announcement['title']);
    final messageController =
        TextEditingController(text: announcement['message']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in both title and message'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() {
                _announcements[index] = {
                  'title': titleController.text.trim(),
                  'message': messageController.text.trim(),
                  'date': announcement['date']!,
                };
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteAnnouncement(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content:
            const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _announcements.removeAt(index);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement deleted successfully!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignCoursesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Courses & Programs'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                SizedBox(height: 24),
                Text(
                  'Course Assignment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This feature is currently being set up to load program and course data from the backend API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 12),
                Text(
                  'Once your backend is connected, you\'ll be able to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• Assign courses to programs\n• Edit curriculum structures\n• Manage course prerequisites\n• View and modify study loads',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
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

  void _showAllStudentsDialog(BuildContext context) {
    String selectedGender = 'All';
    String selectedYearLevel = 'All';
    String selectedDepartment = 'All';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('All Enrolled Students'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Filters
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
                              hint: const Text('Gender'),
                              isExpanded: true,
                              items: ['All', 'Male', 'Female'].map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: selectedYearLevel,
                              hint: const Text('Year Level'),
                              isExpanded: true,
                              items: [
                                'All',
                                '1st Year',
                                '2nd Year',
                                '3rd Year',
                                '4th Year'
                              ].map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedYearLevel = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedDepartment,
                        hint: const Text('Department'),
                        isExpanded: true,
                        items: [
                          'All',
                          'Computer Science',
                          'Information Technology',
                          'Business Administration',
                          'Engineering'
                        ].map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDepartment = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Student List
                Expanded(
                  child: _enrolledStudents.isEmpty
                      ? const Center(
                          child: Text(
                            'No enrolled students found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _enrolledStudents.length,
                          itemBuilder: (context, index) {
                            final student = _enrolledStudents[index];

                            // Apply filters
                            if (selectedGender != 'All' &&
                                student['gender'] != selectedGender) {
                              return const SizedBox.shrink();
                            }
                            if (selectedYearLevel != 'All' &&
                                student['yearLevel'] != selectedYearLevel) {
                              return const SizedBox.shrink();
                            }
                            if (selectedDepartment != 'All' &&
                                student['department'] != selectedDepartment) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[600],
                                  child: Text(
                                    student['studentName']
                                        .toString()
                                        .split(' ')
                                        .map((name) => name[0])
                                        .take(2)
                                        .join('')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  student['studentName'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${student['id']}'),
                                    Text('Email: ${student['email']}'),
                                    Text(
                                        'Year: ${student['yearLevel']} | ${student['department']}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.info,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      _showStudentInfoDialog(context, student),
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
        ),
      ),
    );
  }

  void _showStudentApplicationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Applications'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _studentApplications.isEmpty
              ? const Center(
                  child: Text(
                    'No student applications pending.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _studentApplications.length,
                  itemBuilder: (context, index) {
                    final application = _studentApplications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application['studentName'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text('Email: ${application['email']}'),
                          Text('Applied: ${application['dateApplied']}'),
                          Text('Requirements: ${application['requirements']}'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: application['status'] == 'pending'
                                  ? Colors.orange[100]
                                  : application['status'] == 'approved'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Status: ${application['status'].toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: application['status'] == 'pending'
                                    ? Colors.orange[800]
                                    : application['status'] == 'approved'
                                        ? Colors.green[800]
                                        : Colors.red[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Attached Files:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...application['files']
                              .map<Widget>(
                                (file) => Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.insert_drive_file,
                                          color: Colors.blue[600], size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          file['name'],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        file['size'],
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          if (application['status'] == 'pending') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _approveApplication(context, index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _rejectApplication(context, index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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

  void _approveApplication(BuildContext context, int index) {
    final application = _studentApplications[index];
    setState(() {
      _studentApplications[index]['status'] = 'approved';
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application['studentName']} application approved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectApplication(BuildContext context, int index) {
    final application = _studentApplications[index];
    setState(() {
      _studentApplications[index]['status'] = 'rejected';
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application['studentName']} application rejected!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showStudentInfoDialog(
      BuildContext context, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Student Information'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[600],
                    child: Text(
                      student['studentName']
                          .toString()
                          .split(' ')
                          .map((name) => name[0])
                          .take(2)
                          .join('')
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['studentName'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ID: ${student['id']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: student['status'] == 'Active'
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student['status'],
                            style: TextStyle(
                              color: student['status'] == 'Active'
                                  ? Colors.green[800]
                                  : Colors.red[800],
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

              // Student Details
              _buildInfoRow('Email', student['email'], Icons.email),
              _buildInfoRow(
                  'Contact Number', student['contactNumber'], Icons.phone),
              _buildInfoRow('Address', student['address'], Icons.location_on),
              _buildInfoRow('Gender', student['gender'], Icons.person),
              _buildInfoRow('Year Level', student['yearLevel'], Icons.school),
              _buildInfoRow(
                  'Department', student['department'], Icons.business),
              _buildInfoRow('GPA', student['gpa'], Icons.grade),
              _buildInfoRow('Enrollment Date', student['enrollmentDate'],
                  Icons.calendar_today),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Student record for ${student['studentName']} accessed'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
            child: const Text('Edit Record'),
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
