import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin.dart';
import '../../models/student.dart';
import '../../providers/admin_applications_api_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/admin_bulletins_api_provider.dart';
import '../../providers/admin_resources_api_provider.dart';
import '../../providers/admin_studyloads_api_provider.dart';
import '../../providers/student_provider.dart';
import '../auth/admin_login_screen.dart';
import '../appointments/admin_appointments_screen.dart';
import '../enrollments/admin_application_details_screen.dart';
import '../study_load/admin_study_load_schedule_validation_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _primaryBlue = Color(0xFF1E63B6);
  static const Color _darkBlue = Color(0xFF102A43);
  static const Color _selectedBlue = Color(0xFF2563EB);
  int _selectedIndex = 0;
  bool _hasLoadedInitialData = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialAdminData();
    });
  }

  Future<void> _loadInitialAdminData() async {
    if (_hasLoadedInitialData) return;
    _hasLoadedInitialData = true;

    if (!mounted) return;
    await context.read<StudentProvider>().fetchStudents();

    if (!mounted) return;
    await context.read<AdminApplicationsApiProvider>().fetchAllEnrollments();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<StudentProvider>().fetchStudents();
          context.read<AdminApplicationsApiProvider>().fetchAllEnrollments();
        });
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<StudentProvider>().fetchStudents();
        context.read<AdminApplicationsApiProvider>().fetchAllEnrollments();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AdminAuthProvider>();
    final admin = authProvider.currentAdmin;
    if (admin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final screens = <Widget>[
      _buildHomeTab(admin),
      _buildStudentManagementTab(),
      _buildCourseCurriculumTab(),
      _buildResourcesTab(),
      _buildBulletinsTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context, authProvider),
          ),
        ],
      ),
      drawer: _buildDrawer(context, admin, authProvider),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Student Management';
      case 2:
        return 'Course & Curriculum';
      case 3:
        return 'Resources';
      case 4:
        return 'Bulletins';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _buildDashboardBackground({required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _darkBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.people_alt_rounded, 'Students', 1),
              _buildNavItem(Icons.menu_book_rounded, 'Courses', 2),
              _buildNavItem(Icons.folder_rounded, 'Resources', 3),
              _buildNavItem(Icons.campaign_rounded, 'Bulletins', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavItemTapped(index),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.16),
          highlightColor: Colors.white.withOpacity(0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _selectedBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    Admin admin,
    AdminAuthProvider authProvider,
  ) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F7ED8), Color(0xFF1E63B6)],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 32,
                      color: Color(0xFF3F7ED8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          admin.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Students',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: 'Courses',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.library_books,
                  title: 'Resources',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.campaign,
                  title: 'Bulletins',
                  index: 4,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              _showEditProfileDialog(context, authProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmLogout(context, authProvider);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _primaryBlue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? _primaryBlue : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: _primaryBlue.withOpacity(0.1),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AdminAuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authProvider.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildHomeTab(Admin admin) {
    return _buildDashboardBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: _primaryBlue,
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${admin.fullName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102A43),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            admin.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Consumer2<StudentProvider, AdminApplicationsApiProvider>(
                builder:
                    (context, studentProvider, applicationProvider, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;
                      final cards = [
                        _buildHomeStatCard(
                          icon: Icons.people_alt_rounded,
                          label: 'Students',
                          value: studentProvider.students.length.toString(),
                          color: Colors.blue,
                        ),
                        _buildHomeStatCard(
                          icon: Icons.pending_actions_rounded,
                          label: 'Pending',
                          value: applicationProvider.pendingCount.toString(),
                          color: Colors.orange,
                        ),
                        _buildHomeStatCard(
                          icon: Icons.verified_rounded,
                          label: 'Approved',
                          value: applicationProvider.approvedCount.toString(),
                          color: Colors.green,
                        ),
                        _buildHomeStatCard(
                          icon: Icons.cancel_rounded,
                          label: 'Rejected',
                          value: applicationProvider.rejectedCount.toString(),
                          color: Colors.red,
                        ),
                      ];

                      if (isWide) {
                        return Row(
                          children: cards
                              .map((card) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: card,
                                    ),
                                  ))
                              .toList(),
                        );
                      }

                      return GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.35,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: cards,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionCard(
                icon: Icons.assignment_turned_in_rounded,
                title: 'Manage Enrollments',
                subtitle:
                    'Review pending, approved, and rejected student applications.',
                onTap: () => _onNavItemTapped(1),
              ),
              _buildQuickActionCard(
                icon: Icons.event_available_rounded,
                title: 'Manage Appointments',
                subtitle: 'Open the appointment management screen.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminAppointmentsScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Study Load & Curriculum',
                subtitle:
                    'View or assign course loads by program, year, and semester.',
                onTap: () => _onNavItemTapped(2),
              ),
              _buildQuickActionCard(
                icon: Icons.fact_check_rounded,
                title: 'Validate Study Load Schedules',
                subtitle:
                    'Review student-submitted schedules, professor names, sections, rooms, and time details.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminStudyLoadScheduleValidationScreen(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                icon: Icons.folder_rounded,
                title: 'Learning Resources',
                subtitle: 'Create LMS exam and quiz links for students.',
                onTap: () => _onNavItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _primaryBlue.withOpacity(0.12),
                child: Icon(icon, color: _primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentManagementTab() {
    return _buildDashboardBackground(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: _primaryBlue,
              child: const TabBar(
                tabs: [
                  Tab(text: 'View All Students'),
                  Tab(text: 'View Student Applications'),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildViewAllStudentsContent(),
                  _buildViewStudentApplicationContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCurriculumTab() {
    return _buildDashboardBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildStudyLoadContent(),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'assignCourseFab',
              onPressed: () => _showAssignCourseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Assign Course'),
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return Column(
      children: [
        Expanded(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Learning Resources'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                Consumer<AdminResourcesApiProvider>(
                  builder: (context, provider, child) {
                    return IconButton(
                      tooltip: 'Refresh',
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.fetchResources(),
                      icon: const Icon(Icons.refresh),
                    );
                  },
                ),
              ],
            ),
            body: _buildResourcesContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletinsTab() {
    return _buildDashboardBackground(
      child: _buildBulletinsContent(),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, AdminAuthProvider authProvider) {
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

  Widget _buildStudyLoadContent() {
    return Consumer<AdminStudyLoadsApiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchStudyLoads(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Study Loads',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            'Program',
                            null,
                            ['All', 'BSIT', 'BSBA', 'BSHM', 'BSA'],
                            (value) {
                              if (value != null) {
                                provider.fetchStudyLoads(
                                  programCode: value == 'All' ? null : value,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterDropdown(
                            'Year Level',
                            null,
                            ['All', '1', '2', '3', '4'],
                            (value) {
                              if (value != null) {
                                provider.fetchStudyLoads(
                                  yearLevel: value == 'All'
                                      ? null
                                      : int.tryParse(value),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            'Semester',
                            null,
                            ['All', '1', '2'],
                            (value) {
                              if (value != null) {
                                provider.fetchStudyLoads(
                                  semester: value == 'All'
                                      ? null
                                      : int.tryParse(value),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Course List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Course List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${provider.studyLoads.length} courses',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Course List
              Expanded(
                child: provider.studyLoads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No courses found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => provider.fetchStudyLoads(),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: provider.studyLoads.length,
                          itemBuilder: (context, index) {
                            final course = provider.studyLoads[index];
                            return _buildCourseCard(context, course);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    final subjectCode = course['subjectCode']?.toString() ?? 'N/A';
    final subjectTitle =
        course['subjectTitle']?.toString() ?? 'Unknown Subject';
    final lecUnits = course['lecUnits']?.toString() ?? '0';
    final labUnits = course['labUnits']?.toString() ?? '0';
    final totalUnits =
        (double.tryParse(lecUnits) ?? 0) + (double.tryParse(labUnits) ?? 0);
    final programCode = course['programCode']?.toString() ?? 'N/A';
    final yearLevel = course['yearLevel']?.toString() ?? 'N/A';
    final semester = course['semester']?.toString() ?? 'N/A';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            subjectCode.substring(
                0, subjectCode.length > 2 ? 2 : subjectCode.length),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(subjectTitle),
        subtitle: Text(
            '$subjectCode • $programCode - Year $yearLevel, Sem $semester'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$totalUnits units',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'Lec: $lecUnits | Lab: $labUnits',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesContent() {
    return Consumer<AdminResourcesApiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchResources(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final examLink = provider.resources
            .where((r) {
              final type = r['resourceType']?.toString().toLowerCase();
              return type == 'exam' || type == 'lms exam';
            })
            .take(1)
            .toList();

        final quizLink = provider.resources
            .where((r) {
              final type = r['resourceType']?.toString().toLowerCase();
              return type == 'quiz' || type == 'lms quiz';
            })
            .take(1)
            .toList();

        return Container(
          padding: const EdgeInsets.all(16),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.assignment),
                        text: 'LMS Exam Link',
                      ),
                      Tab(
                        icon: Icon(Icons.quiz),
                        text: 'LMS Quiz Link',
                      ),
                    ],
                    indicatorColor: Colors.blue,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildInlineResourceEditor(
                        context: context,
                        provider: provider,
                        resourceType: 'Exam',
                        displayTitle: 'LMS Exam Link',
                        icon: Icons.assignment,
                        color: Colors.orange,
                        currentResource:
                            examLink.isNotEmpty ? examLink.first : null,
                      ),
                      _buildInlineResourceEditor(
                        context: context,
                        provider: provider,
                        resourceType: 'Quiz',
                        displayTitle: 'LMS Quiz Link',
                        icon: Icons.quiz,
                        color: Colors.purple,
                        currentResource:
                            quizLink.isNotEmpty ? quizLink.first : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineResourceEditor({
    required BuildContext context,
    required AdminResourcesApiProvider provider,
    required String resourceType,
    required String displayTitle,
    required IconData icon,
    required Color color,
    required Map<String, dynamic>? currentResource,
  }) {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: currentResource?['title']?.toString() ?? '',
    );

    final urlController = TextEditingController(
      text: currentResource?['url']?.toString() ?? '',
    );

    final hasCurrentLink = currentResource != null;
    final currentTitle = currentResource?['title']?.toString() ?? '';
    final currentUrl = currentResource?['url']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color,
                        child: Icon(icon, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasCurrentLink
                              ? 'Replace $displayTitle'
                              : 'Add $displayTitle',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Resource Title',
                      hintText: resourceType == 'Exam'
                          ? 'e.g. Midterm Exam Link'
                          : 'e.g. Quiz 1 Link',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a resource title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Link',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a URL link';
                      }

                      final url = value.trim();

                      if (!url.startsWith('http://') &&
                          !url.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final success = await provider.createResource(
                                resourceType: resourceType,
                                title: titleController.text.trim(),
                                url: urlController.text.trim(),
                              );

                              if (!context.mounted) return;

                              if (success) {
                                await provider.fetchResources();

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      hasCurrentLink
                                          ? '$displayTitle replaced and sent to students.'
                                          : '$displayTitle added and sent to students.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.errorMessage ??
                                          'Failed to save $displayTitle.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        hasCurrentLink
                            ? 'Replace and Send to Students'
                            : 'Add and Send to Students',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(height: 18),
          Text(
            'Current $displayTitle',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasCurrentLink)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    resourceType == 'Exam'
                        ? Icons.assignment_outlined
                        : Icons.quiz_outlined,
                    size: 52,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No $displayTitle yet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add a link above to send it to students.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          currentUrl,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open link',
                    onPressed: () => _openUrl(currentUrl),
                    icon: const Icon(Icons.open_in_new),
                    color: color,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceList(
      List<Map<String, dynamic>> resources, String type, Color color) {
    if (resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'LMS Exam'
                  ? Icons.assignment_outlined
                  : Icons.quiz_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type links yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add a resource',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: resources.length,
        itemBuilder: (context, index) {
          final resource = resources[index];
          return _buildResourceCard(context, resource, type, color);
        },
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    Map<String, dynamic> resource,
    String type,
    Color color,
  ) {
    final title = resource['title']?.toString() ?? 'Untitled';
    final url = resource['url']?.toString() ?? '';

    IconData iconData;
    switch (type) {
      case 'LMS Exam':
        iconData = Icons.assignment;
        break;
      case 'LMS Quiz':
        iconData = Icons.quiz;
        break;
      default:
        iconData = Icons.link;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(iconData, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          url.length > 40 ? '${url.substring(0, 40)}...' : url,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showNotifyStudentDialog(context, resource),
              icon: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
              tooltip: 'Notify Students',
            ),
            IconButton(
              onPressed: () => _openUrl(url),
              icon: const Icon(
                Icons.open_in_new,
                color: Colors.blue,
              ),
              tooltip: 'Open Link',
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    // TODO: Implement URL launcher
    // For now, just print the URL
    debugPrint('Opening URL: $url');
  }

  void _showNotifyStudentDialog(
      BuildContext context, Map<String, dynamic> resource) {
    final messageController = TextEditingController(
      text: 'New ${resource['resourceType']} available: ${resource['title']}',
    );
    final List<String> selectedPrograms = [];
    final List<String> selectedYearLevels = [];
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Notify Students'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resource: ${resource['title']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Message',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Target Programs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['BSIT', 'BSBA', 'BSHM', 'BSA'].map((program) {
                        final isSelected = selectedPrograms.contains(program);
                        return FilterChip(
                          label: Text(program),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedPrograms.add(program);
                              } else {
                                selectedPrograms.remove(program);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Target Year Levels:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['1st Year', '2nd Year', '3rd Year', '4th Year']
                          .map((year) {
                        final isSelected = selectedYearLevels.contains(year);
                        return FilterChip(
                          label: Text(year),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedYearLevels.add(year);
                              } else {
                                selectedYearLevels.remove(year);
                              }
                            });
                          },
                        );
                      }).toList(),
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
              ElevatedButton.icon(
                onPressed: () async {
                  // TODO: Implement notification API call
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification sent to selected students'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Notification'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddResourceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String selectedType = 'Exam';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Learning Resource'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Resource Type Selection
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'LMS Exam',
                            label: Text('LMS Exam'),
                            icon: Icon(Icons.assignment),
                          ),
                          ButtonSegment(
                            value: 'LMS Quiz',
                            label: Text('LMS Quiz'),
                            icon: Icon(Icons.quiz),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setDialogState(() {
                            selectedType = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Title
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Resource Title',
                          hintText: 'e.g., Midterm Review Materials',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // URL
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Link',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a URL';
                          }
                          if (!value.startsWith('http')) {
                            return 'Please enter a valid URL starting with http';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              Consumer<AdminResourcesApiProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final success = await provider.createResource(
                                resourceType: selectedType,
                                title: titleController.text.trim(),
                                url: urlController.text.trim(),
                              );
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Resource added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage ??
                                        'Failed to add resource'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Resource'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignCourseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final subjectCodeController = TextEditingController();
    final subjectTitleController = TextEditingController();
    final lecUnitsController = TextEditingController();
    final labUnitsController = TextEditingController();
    String selectedProgram = 'BSIT';
    String selectedYear = '1';
    String selectedSemester = '1';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign New Course'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Program, Year, Semester filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedProgram,
                              decoration: const InputDecoration(
                                labelText: 'Program',
                                border: OutlineInputBorder(),
                              ),
                              items: ['BSIT', 'BSBA', 'BSHM', 'BSA']
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => selectedProgram = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Year Level',
                                border: OutlineInputBorder(),
                              ),
                              items: ['1', '2', '3', '4']
                                  .map((y) => DropdownMenuItem(
                                      value: y, child: Text('Year $y')))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => selectedYear = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSemester,
                              decoration: const InputDecoration(
                                labelText: 'Semester',
                                border: OutlineInputBorder(),
                              ),
                              items: ['1', '2']
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text('Sem $s')))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(
                                      () => selectedSemester = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Subject Details
                      TextFormField(
                        controller: subjectCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Code',
                          hintText: 'e.g., IT101',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subject code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Title',
                          hintText: 'e.g., Introduction to Programming',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subject title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: lecUnitsController,
                              decoration: const InputDecoration(
                                labelText: 'Lec Units',
                                hintText: 'e.g., 3',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: labUnitsController,
                              decoration: const InputDecoration(
                                labelText: 'Lab Units',
                                hintText: 'e.g., 1',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              Consumer<AdminStudyLoadsApiProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final success = await provider.createStudyLoad(
                                programCode: selectedProgram,
                                yearLevel: int.parse(selectedYear),
                                semester: int.parse(selectedSemester),
                                subjectCode: subjectCodeController.text.trim(),
                                subjectTitle:
                                    subjectTitleController.text.trim(),
                                lecUnits: double.parse(
                                    lecUnitsController.text.trim()),
                                labUnits: double.parse(
                                    labUnitsController.text.trim()),
                              );
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Course assigned successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage ??
                                        'Failed to assign course'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Assign Course'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewAllStudentsContent() {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        if (studentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (studentProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${studentProvider.errorMessage}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => studentProvider.fetchStudents(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredStudents = _getFilteredStudents(studentProvider);

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Gender',
                      studentProvider.selectedGender,
                      ['All', 'Male', 'Female'],
                      (value) {
                        if (value != null) {
                          studentProvider.setGenderFilter(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Year Level',
                      studentProvider.selectedYear,
                      ['All', '1st Year', '2nd Year', '3rd Year', '4th Year'],
                      (value) {
                        if (value != null) {
                          studentProvider.setYearFilter(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Course',
                      studentProvider.selectedCourse,
                      ['All', 'BSIT', 'BSBA', 'BSHM', 'BSA'],
                      (value) {
                        if (value != null) {
                          studentProvider.setCourseFilter(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Student Type',
                      studentProvider.selectedType,
                      ['All', 'Transferee', 'Continuing', 'New/Incoming'],
                      (value) {
                        if (value != null) {
                          studentProvider.setTypeFilter(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enrolled Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${filteredStudents.length} students',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No students match the selected filters',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                studentProvider.clearFilters();
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return _buildStudentCardFromModel(context, student);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Student> _getFilteredStudents(StudentProvider provider) {
    return provider.students.where((student) {
      final matchesGender = _matchesTextFilter(
        student.gender,
        provider.selectedGender,
      );

      final matchesCourse = _matchesTextFilter(
        student.program,
        provider.selectedCourse,
      );

      final matchesYear = _matchesYearFilter(
        student.yearLevel,
        provider.selectedYear,
      );

      final matchesType = _matchesStudentTypeFilter(
        student.studentType,
        provider.selectedType,
      );

      return matchesGender && matchesCourse && matchesYear && matchesType;
    }).toList();
  }

  bool _matchesTextFilter(String actualValue, String? selectedValue) {
    if (_isAllFilter(selectedValue)) {
      return true;
    }

    return _normalize(actualValue) == _normalize(selectedValue!);
  }

  bool _matchesYearFilter(String actualYear, String? selectedYear) {
    if (_isAllFilter(selectedYear)) {
      return true;
    }

    return _normalizeYear(actualYear) == _normalizeYear(selectedYear!);
  }

  bool _matchesStudentTypeFilter(String actualType, String? selectedType) {
    if (_isAllFilter(selectedType)) {
      return true;
    }

    return _normalizeStudentType(actualType) ==
        _normalizeStudentType(selectedType!);
  }

  bool _isAllFilter(String? value) {
    if (value == null) {
      return true;
    }

    final normalized = value.trim().toLowerCase();

    return normalized.isEmpty || normalized == 'all';
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _normalizeYear(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.contains('1')) return '1';
    if (normalized.contains('2')) return '2';
    if (normalized.contains('3')) return '3';
    if (normalized.contains('4')) return '4';

    return normalized;
  }

  String _normalizeStudentType(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('/', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
  }

  Widget _buildStudentCard(
    BuildContext context, {
    required String initials,
    required String name,
    required String program,
    required String year,
    required String gender,
    required String type,
    required String email,
    required String phone,
    required String address,
    required Color avatarColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name),
        subtitle: Text('$program - $year • $gender • $type'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _showStudentDetailsDialog(
            context,
            name: name,
            initials: initials,
            program: program,
            year: year,
            gender: gender,
            type: type,
            email: email,
            phone: phone,
            address: address,
            avatarColor: avatarColor,
          ),
        ),
      ),
    );
  }

  void _showStudentDetailsDialog(
    BuildContext context, {
    required String name,
    required String initials,
    required String program,
    required String year,
    required String gender,
    required String type,
    required String email,
    required String phone,
    required String address,
    required Color avatarColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: avatarColor,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(type),
                        backgroundColor: avatarColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                            color: avatarColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.school, 'Program', program),
                      _buildInfoRow(Icons.calendar_today, 'Year Level', year),
                      _buildInfoRow(Icons.person, 'Gender', gender),
                      _buildInfoRow(Icons.email, 'Email', email),
                      _buildInfoRow(Icons.phone, 'Phone', phone),
                      _buildInfoRow(Icons.location_on, 'Address', address),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: avatarColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> items, [
    void Function(String?)? onChanged,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(label,
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500)),
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged ?? (val) {},
        ),
      ),
    );
  }

  Widget _buildStudentCardFromModel(BuildContext context, Student student) {
    final avatarColor = _getAvatarColor(student.program);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            student.initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student.fullName),
        subtitle: Text(
            '${student.program} - ${student.yearLevel} • ${student.gender} • ${student.studentType}'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () =>
              _showStudentDetailsDialogFromModel(context, student, avatarColor),
        ),
      ),
    );
  }

  Color _getAvatarColor(String program) {
    switch (program.toUpperCase()) {
      case 'BSIT':
        return Colors.blue;
      case 'BSBA':
        return Colors.green;
      case 'BSHM':
        return Colors.purple;
      case 'BSA':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showStudentDetailsDialogFromModel(
      BuildContext context, Student student, Color avatarColor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: avatarColor,
                        child: Text(
                          student.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(student.studentType),
                        backgroundColor: avatarColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                            color: avatarColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.school, 'Program', student.program),
                      _buildInfoRow(Icons.calendar_today, 'Year Level',
                          student.yearLevel),
                      _buildInfoRow(Icons.person, 'Gender', student.gender),
                      _buildInfoRow(Icons.email, 'Email', student.email),
                      _buildInfoRow(Icons.phone, 'Phone',
                          student.phoneNumber ?? 'Not provided'),
                      _buildInfoRow(Icons.location_on, 'Address',
                          student.address ?? 'Not provided'),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: avatarColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewStudentApplicationContent() {
    return Consumer<AdminApplicationsApiProvider>(
      builder: (context, provider, child) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.blue[700],
                child: TabBar(
                  tabs: [
                    Tab(text: 'Pending (${provider.pendingCount})'),
                    Tab(text: 'Approved (${provider.approvedCount})'),
                    Tab(text: 'Rejected (${provider.rejectedCount})'),
                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorWeight: 3,
                ),
              ),
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
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.fetchAllEnrollments(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildApplicationList('PendingReview', provider),
                          _buildApplicationList('Approved', provider),
                          _buildApplicationList('Rejected', provider),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApplicationList(
      String status, AdminApplicationsApiProvider provider) {
    final applications = provider.getEnrollmentsByStatus(status);
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'PendingReview'
                  ? Icons.hourglass_empty
                  : status == 'Approved'
                      ? Icons.check_circle
                      : Icons.cancel,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status == 'PendingReview' ? 'pending' : status.toLowerCase()} applications',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: RefreshIndicator(
        onRefresh: () => provider.fetchAllEnrollments(),
        child: ListView.builder(
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            return _buildApplicationCard(
                context, application, status, provider);
          },
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    Map<String, dynamic> application,
    String status,
    AdminApplicationsApiProvider provider,
  ) {
    final firstName = application['firstName']?.toString() ?? '';
    final lastName = application['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim().isEmpty
        ? 'Unnamed Student'
        : '$firstName $lastName'.trim();
    final studentType = application['studentType']?.toString() ?? '-';
    final programCode = application['programCode']?.toString() ?? '-';
    final yearLevel = application['yearLevel']?.toString() ?? '-';
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'PendingReview':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.close;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white),
        ),
        title: Text(
          fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$programCode - $yearLevel • $studentType'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                    Icons.person_outline, 'Student Type', studentType),
                _buildInfoRow(Icons.school, 'Program', programCode),
                _buildInfoRow(Icons.calendar_today, 'Year Level', yearLevel),
                _buildInfoRow(Icons.email, 'Email',
                    application['email']?.toString() ?? 'N/A'),
                _buildInfoRow(Icons.access_time, 'Submitted',
                    _formatDate(application['submittedAt'])),
                if (status == 'Rejected' &&
                    application['rejectionReason'] != null)
                  _buildInfoRow(Icons.warning, 'Rejection Reason',
                      application['rejectionReason'].toString()),
                const SizedBox(height: 16),
                if (status == 'PendingReview') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(
                              context, application, provider),
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
                              _showRejectDialog(context, application, provider),
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
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to application details
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AdminApplicationDetailsScreen(
                              applicationId: application['id'].toString(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.tryParse(dateValue.toString());
      if (date == null) return 'N/A';
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showApproveDialog(BuildContext context,
      Map<String, dynamic> application, AdminApplicationsApiProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text(
            'Are you sure you want to approve ${application['firstName']} ${application['lastName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider
                  .approveEnrollment(application['id'].toString());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Application approved successfully'
                        : provider.errorMessage ?? 'Failed to approve'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Map<String, dynamic> application,
      AdminApplicationsApiProvider provider) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Are you sure you want to reject ${application['firstName']} ${application['lastName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a rejection reason')),
                );
                return;
              }
              Navigator.pop(context);
              final success = await provider.rejectEnrollment(
                application['id'].toString(),
                reasonController.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Application rejected'
                        : provider.errorMessage ?? 'Failed to reject'),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bulletin Management',
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bulletins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Consumer<AdminBulletinsApiProvider>(
                builder: (context, provider, child) {
                  return IconButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.fetchBulletins(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildRecentBulletinsPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBulletinsPreview() {
    return Consumer<AdminBulletinsApiProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchBulletins(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (provider.bulletins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No bulletins posted yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showPostAnnouncementDialog(context),
                  icon: const Icon(Icons.post_add),
                  label: const Text('Create First Bulletin'),
                ),
              ],
            ),
          );
        }
        final recentBulletins = provider.bulletins.take(5).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recentBulletins.length,
            itemBuilder: (context, index) {
              final bulletin = recentBulletins[index];
              return _buildBulletinPreviewCard(context, bulletin);
            },
          ),
        );
      },
    );
  }

  Widget _buildBulletinPreviewCard(
      BuildContext context, Map<String, dynamic> bulletin) {
    final title = bulletin['title']?.toString() ?? 'Untitled';
    final content = bulletin['content']?.toString() ?? '';
    final isPublished = bulletin['isPublished'] == true;
    final createdAt = bulletin['createdAt']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPublished ? Colors.green : Colors.orange,
          child: Icon(
            isPublished ? Icons.public : Icons.drafts,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          content.length > 50 ? '${content.substring(0, 50)}...' : content,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _formatBulletinDate(createdAt),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        onTap: () => _showManagePostsDialog(context),
      ),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostAnnouncementDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isPublished = true;
    String audienceType = 'All Students';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Post Announcement'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter announcement title...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          hintText: 'Enter announcement content...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: audienceType,
                        decoration: const InputDecoration(
                          labelText: 'Target Audience',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'All Students',
                          'Specific Programs',
                          'Specific Year Levels'
                        ]
                            .map((type) => DropdownMenuItem(
                                value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => audienceType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Publish Immediately'),
                        value: isPublished,
                        onChanged: (value) {
                          setDialogState(() => isPublished = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              Consumer<AdminBulletinsApiProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final success = await provider.createBulletin(
                                title: titleController.text.trim(),
                                content: contentController.text.trim(),
                              );
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Announcement posted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage ??
                                        'Failed to post announcement'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: provider.isLoading
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
          );
        },
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
          child: Consumer<AdminBulletinsApiProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.bulletins.isEmpty) {
                return const Center(
                  child: Text('No bulletins to manage'),
                );
              }
              return ListView.builder(
                itemCount: provider.bulletins.length,
                itemBuilder: (context, index) {
                  final bulletin = provider.bulletins[index];
                  final title = bulletin['title']?.toString() ?? 'Untitled';
                  final isPublished = bulletin['isPublished'] == true;
                  final bulletinId = bulletin['id']?.toString() ?? '';
                  return ListTile(
                    leading: Icon(
                      isPublished ? Icons.public : Icons.drafts,
                      color: isPublished ? Colors.green : Colors.orange,
                    ),
                    title: Text(title),
                    subtitle: Text(isPublished ? 'Published' : 'Draft'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final newStatus = !isPublished;
                            final success = await provider.updateBulletin(
                              id: bulletinId,
                              title: bulletin['title']?.toString() ?? '',
                              content: bulletin['content']?.toString() ?? '',
                              isPublished: newStatus,
                            );
                            if (context.mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(newStatus
                                      ? 'Bulletin published'
                                      : 'Bulletin unpublished'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: Icon(
                              isPublished ? Icons.unpublished : Icons.publish),
                        ),
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Bulletin?'),
                                content:
                                    const Text('This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final success =
                                  await provider.deleteBulletin(bulletinId);
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bulletin deleted'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
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

  String _formatBulletinDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.tryParse(dateString);
      if (date == null) return 'N/A';
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
