import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';



import '../../models/admin.dart';

import '../../models/student.dart';

import '../../providers/admin_applications_api_provider.dart';

import '../../providers/admin_auth_provider.dart';

import '../../providers/admin_bulletins_api_provider.dart';

import '../../providers/admin_resources_api_provider.dart';

import '../../providers/admin_studyloads_api_provider.dart';

import '../../providers/student_provider.dart';

import '../appointments/admin_appointments_screen.dart';

import '../auth/admin_login_screen.dart';

import '../enrollments/admin_application_details_screen.dart';

import '../enrollments/admin_enrollment_api_screen.dart';



class AdminDashboard extends StatefulWidget {

  const AdminDashboard({super.key});



  @override

  State<AdminDashboard> createState() => _AdminDashboardState();

}



class _AdminDashboardState extends State<AdminDashboard> {

  int _selectedIndex = 0;





  void _onNavItemTapped(int index) {

    setState(() {

      _selectedIndex = index;

    });

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



    final List<Widget> screens = [

      _buildHomeTab(context, admin, authProvider),

      _buildStudentManagementTab(),

      _buildCourseCurriculumTab(),

      _buildResourcesTab(),

      _buildBulletinsTab(),

    ];



    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context, admin, authProvider),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDrawer(BuildContext context, Admin admin, AdminAuthProvider authProvider) {
    return Drawer(
      child: Column(
        children: [
          // Header
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
                    child: Icon(Icons.admin_panel_settings, size: 32, color: Color(0xFF3F7ED8)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          admin.email,
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
          const Divider(),
          // Edit Profile
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
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              Navigator.pop(context);
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A2B4A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.people, 'Students', 1),
              _buildNavItem(Icons.school, 'Courses', 2),
              _buildNavItem(Icons.article, 'Resources', 3),
              _buildNavItem(Icons.campaign, 'Bulletins', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNavItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AdminAuthProvider authProvider) {
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

  Widget _buildHomeTab(BuildContext context, Admin admin, AdminAuthProvider authProvider) {

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
        body: SingleChildScrollView(

          padding: const EdgeInsets.all(16.0),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                'Welcome, ${admin.fullName}!',

                style: const TextStyle(

                  fontSize: 24,

                  fontWeight: FontWeight.bold,

                  color: Colors.white,

                ),

              ),

              const SizedBox(height: 4),

              Text(

                'Role: ${_getRoleDisplay(admin.role)}',

                style: const TextStyle(

                  fontSize: 14,

                  color: Colors.white70,

                ),

              ),

              const SizedBox(height: 24),

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

                        _onNavItemTapped(1);

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

                        _onNavItemTapped(2);

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



  Widget _buildStudentManagementTab() {

    return Column(

      children: [

        Expanded(

          child: FutureBuilder(

            future: _fetchStudentsOnce(context),

            builder: (context, snapshot) {

              return DefaultTabController(

                length: 2,

                child: Scaffold(

                  backgroundColor: Colors.transparent,

                  appBar: AppBar(

                    title: const Text('Student Management'),

                    backgroundColor: Colors.blue,

                    foregroundColor: Colors.white,

                    elevation: 0,

                    bottom: const TabBar(

                      tabs: [

                        Tab(text: 'View All Students'),

                        Tab(text: 'View Student Application'),

                      ],

                      indicatorColor: Colors.white,

                      labelColor: Colors.white,

                      unselectedLabelColor: Colors.white70,

                    ),

                  ),

                  body: TabBarView(

                    children: [

                      _buildViewAllStudentsContent(),

                      _buildViewStudentApplicationContent(),

                    ],

                  ),

                ),

              );

            },

          ),

        ),


      ],

    );

  }



  Widget _buildCourseCurriculumTab() {

    return Column(

      children: [

        Expanded(

          child: Scaffold(

            backgroundColor: Colors.transparent,

            appBar: AppBar(

              title: const Text('Study Load & Curriculum'),

              backgroundColor: Colors.blue,

              foregroundColor: Colors.white,

              elevation: 0,


            ),

            body: _buildStudyLoadContent(),

            floatingActionButton: FloatingActionButton.extended(

              onPressed: () => _showAssignCourseDialog(context),

              icon: const Icon(Icons.add),

              label: const Text('Assign Course'),

              backgroundColor: Colors.blue,

            ),

          ),

        ),


      ],

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

                            provider.selectedProgram ?? 'All',

                            ['All', 'BSIT', 'BSBA', 'BSHM', 'BSA'],

                            (value) {

                              if (value != null) {

                                provider.fetchStudyLoads(

                                  programCode: value == 'All' ? null : value,

                                  yearLevel: provider.selectedYear,

                                  semester: provider.selectedSemester,

                                );

                              }

                            },

                          ),

                        ),

                        const SizedBox(width: 8),

                        Expanded(

                          child: _buildFilterDropdown(

                            'Year Level',

                            provider.selectedYear?.toString() ?? 'All',

                            ['All', '1', '2', '3', '4'],

                            (value) {

                              if (value != null) {

                                provider.fetchStudyLoads(

                                  programCode: provider.selectedProgram,

                                  yearLevel: value == 'All' ? null : int.tryParse(value),

                                  semester: provider.selectedSemester,

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

                            provider.selectedSemester?.toString() ?? 'All',

                            ['All', '1', '2'],

                            (value) {

                              if (value != null) {

                                provider.fetchStudyLoads(

                                  programCode: provider.selectedProgram,

                                  yearLevel: provider.selectedYear,

                                  semester: value == 'All' ? null : int.tryParse(value),

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

                            final course = Map<String, dynamic>.from(provider.studyLoads[index]);

                            // Ensure type safety by converting values
                            if (course['yearLevel'] is int) {
                              course['yearLevel'] = course['yearLevel'].toString();
                            }

                            if (course['semester'] is int) {
                              course['semester'] = course['semester'].toString();
                            }

                            return _buildCourseCard(context, course, provider);

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



  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course, AdminStudyLoadsApiProvider provider) {

    final id = course['id'] is int ? course['id'] as int : int.tryParse(course['id']?.toString() ?? '') ?? 0;

    final subjectCode = course['subjectCode']?.toString() ?? 'N/A';

    final subjectTitle = course['subjectTitle']?.toString() ?? 'Unknown Subject';

    // Safely convert units to strings
    final lecUnitsStr = course['lecUnits']?.toString() ?? '0';

    final labUnitsStr = course['labUnits']?.toString() ?? '0';

    final lecUnits = double.tryParse(lecUnitsStr) ?? 0.0;

    final labUnits = double.tryParse(labUnitsStr) ?? 0.0;

    final totalUnits = lecUnits + labUnits;

    final programCode = course['programCode']?.toString() ?? 'N/A';

    final yearLevel = course['yearLevel']?.toString() ?? 'N/A';

    final semester = course['semester']?.toString() ?? 'N/A';



    return Card(

      margin: const EdgeInsets.only(bottom: 8),

      child: ListTile(

        leading: CircleAvatar(

          backgroundColor: Colors.blue,

          child: Text(

            subjectCode.substring(0, subjectCode.length > 2 ? 2 : subjectCode.length),

            style: const TextStyle(

              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize: 12,

            ),

          ),

        ),

        title: Text(subjectTitle),

        subtitle: Text('$subjectCode • $programCode - Year $yearLevel, Sem $semester'),

        trailing: Row(

          mainAxisSize: MainAxisSize.min,

          children: [

            Column(

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

                  'Lec: ${lecUnits.toStringAsFixed(1)} | Lab: ${labUnits.toStringAsFixed(1)}',

                  style: const TextStyle(

                    fontSize: 10,

                    color: Colors.grey,

                  ),

                ),

              ],

            ),

            const SizedBox(width: 8),

            IconButton(

              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),

              onPressed: () => _showEditCourseDialog(context, course, provider),

            ),

          ],

        ),

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


            ),

            body: _buildResourcesContent(),


          ),

        ),


      ],

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



        // Filter resources by type

        final examLinks = provider.resources.where((r) => r['resourceType']?.toString().toLowerCase() == 'lms exam').toList();

        final quizLinks = provider.resources.where((r) => r['resourceType']?.toString().toLowerCase() == 'lms quiz').toList();



        return Container(

          padding: const EdgeInsets.all(16),

          child: DefaultTabController(

            length: 2,

            child: Column(

              children: [

                // Tab Bar

                Container(

                  decoration: BoxDecoration(

                    color: Colors.white.withOpacity(0.9),

                    borderRadius: BorderRadius.circular(12),

                  ),

                  child: TabBar(

                    tabs: [

                      Tab(

                        icon: const Icon(Icons.assignment),

                        text: 'LMS Exam Link (${examLinks.length})',

                      ),

                      Tab(

                        icon: const Icon(Icons.quiz),

                        text: 'LMS Quiz Link (${quizLinks.length})',

                      ),

                    ],

                    indicatorColor: Colors.blue,

                    labelColor: Colors.blue,

                    unselectedLabelColor: Colors.grey,

                  ),

                ),

                const SizedBox(height: 16),

                // Tab Views

                Expanded(

                  child: TabBarView(

                    children: [

                      Scaffold(
                        backgroundColor: Colors.transparent,
                        body: _buildResourceList(examLinks, 'LMS Exam', Colors.orange),
                        floatingActionButton: FloatingActionButton.extended(
                          onPressed: () => _showAddResourceDialog(context, initialType: 'LMS Exam'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exam'),
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      Scaffold(
                        backgroundColor: Colors.transparent,
                        body: _buildResourceList(quizLinks, 'LMS Quiz', Colors.purple),
                        floatingActionButton: FloatingActionButton.extended(
                          onPressed: () => _showAddResourceDialog(context, initialType: 'LMS Quiz'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Quiz'),
                          backgroundColor: Colors.purple,
                        ),
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



  Widget _buildResourceList(List<Map<String, dynamic>> resources, String type, Color color) {

    if (resources.isEmpty) {

      return Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(

              type == 'LMS Exam' ? Icons.assignment_outlined : Icons.quiz_outlined,

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



  Widget _buildResourceCard(BuildContext context, Map<String, dynamic> resource, String type, Color color) {

    final title = resource['title']?.toString() ?? 'Untitled';

    final url = resource['url']?.toString() ?? '';

    final resourceId = resource['id']?.toString() ?? '';



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

            // Notify button

            IconButton(

              onPressed: () => _showNotifyStudentDialog(context, resource),

              icon: const Icon(Icons.notifications_active, color: Colors.orange),

              tooltip: 'Notify Students',

            ),

            // Open link button

            IconButton(

              onPressed: () => _openUrl(url),

              icon: const Icon(Icons.open_in_new, color: Colors.blue),

              tooltip: 'Open Link',

            ),

          ],

        ),

      ),

    );

  }



  Future<void> _openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('Invalid URL: $url');
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }



  void _showNotifyStudentDialog(BuildContext context, Map<String, dynamic> resource) {

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

                      children: ['1st Year', '2nd Year', '3rd Year', '4th Year'].map((year) {

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



  void _showAddResourceDialog(BuildContext context, {String? initialType}) {

    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController();

    final urlController = TextEditingController();

    String selectedType = initialType ?? 'LMS Exam';



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

                          if (value == null || value.trim().isEmpty) {

                            return 'Please enter a URL';

                          }

                          final trimmed = value.trim();

                          if (!trimmed.toLowerCase().startsWith('http://') && !trimmed.toLowerCase().startsWith('https://')) {

                            return 'Please enter a valid URL starting with http:// or https://';

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

                                    content: Text('Resource added successfully'),

                                    backgroundColor: Colors.green,

                                  ),

                                );

                              } else {

                                ScaffoldMessenger.of(context).showSnackBar(

                                  SnackBar(

                                    content: Text(provider.errorMessage ?? 'Failed to add resource'),

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

                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))

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

                                  .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))

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

                                  .map((s) => DropdownMenuItem(value: s, child: Text('Sem $s')))

                                  .toList(),

                              onChanged: (value) {

                                if (value != null) {

                                  setDialogState(() => selectedSemester = value);

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

                                subjectTitle: subjectTitleController.text.trim(),

                                lecUnits: double.parse(lecUnitsController.text.trim()),

                                labUnits: double.parse(labUnitsController.text.trim()),

                              );



                              if (!context.mounted) return;



                              if (success) {

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(

                                  const SnackBar(

                                    content: Text('Course assigned successfully'),

                                    backgroundColor: Colors.green,

                                  ),

                                );

                              } else {

                                ScaffoldMessenger.of(context).showSnackBar(

                                  SnackBar(

                                    content: Text(provider.errorMessage ?? 'Failed to assign course'),

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



  void _showEditCourseDialog(BuildContext context, Map<String, dynamic> course, AdminStudyLoadsApiProvider provider) {

    final formKey = GlobalKey<FormState>();

    final id = course['id'] as int? ?? 0;

    final subjectCodeController = TextEditingController(text: course['subjectCode']?.toString() ?? '');

    final subjectTitleController = TextEditingController(text: course['subjectTitle']?.toString() ?? '');

    final lecUnitsController = TextEditingController(text: course['lecUnits']?.toString() ?? '');

    final labUnitsController = TextEditingController(text: course['labUnits']?.toString() ?? '');

    String selectedProgram = course['programCode']?.toString() ?? 'BSIT';

    String selectedYear = course['yearLevel']?.toString() ?? '1';

    String selectedSemester = course['semester']?.toString() ?? '1';



    showDialog(

      context: context,

      builder: (dialogContext) => StatefulBuilder(

        builder: (context, setDialogState) {

          return AlertDialog(

            title: const Text('Edit Course'),

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

                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))

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

                                  .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))

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

                                  .map((s) => DropdownMenuItem(value: s, child: Text('Sem $s')))

                                  .toList(),

                              onChanged: (value) {

                                if (value != null) {

                                  setDialogState(() => selectedSemester = value);

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

              ElevatedButton(

                onPressed: provider.isLoading

                    ? null

                    : () async {

                        if (formKey.currentState!.validate()) {

                          final success = await provider.updateStudyLoad(

                            id: id,

                            programCode: selectedProgram,

                            yearLevel: int.parse(selectedYear),

                            semester: int.parse(selectedSemester),

                            subjectCode: subjectCodeController.text.trim(),

                            subjectTitle: subjectTitleController.text.trim(),

                            lecUnits: double.parse(lecUnitsController.text.trim()),

                            labUnits: double.parse(labUnitsController.text.trim()),

                          );



                          if (!context.mounted) return;



                          if (success) {

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(

                              const SnackBar(

                                content: Text('Course updated successfully'),

                                backgroundColor: Colors.green,

                              ),

                            );

                          } else {

                            ScaffoldMessenger.of(context).showSnackBar(

                              SnackBar(

                                content: Text(provider.errorMessage ?? 'Failed to update course'),

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

                    : const Text('Save Changes'),

              ),

            ],

          );

        },

      ),

    );

  }



  Future<void> _fetchStudentsOnce(BuildContext context) async {

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    // Only fetch if students list is empty (first load)

    if (studentProvider.students.isEmpty) {

      await studentProvider.fetchStudents();

    }

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

                    '${studentProvider.students.length} students',

                    style: const TextStyle(

                      fontSize: 14,

                      color: Colors.white70,

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 12),

              Expanded(

                child: studentProvider.students.isEmpty

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

                              'No students found',

                              style: TextStyle(

                                color: Colors.white,

                                fontSize: 18,

                              ),

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

                          itemCount: studentProvider.students.length,

                          itemBuilder: (context, index) {

                            final student = studentProvider.students[index];

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

            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

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

                        labelStyle: TextStyle(color: avatarColor, fontWeight: FontWeight.w600),

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

                  padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),

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

          hint: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),

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

            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

          ),

        ),

        title: Text(student.fullName),

        subtitle: Text('${student.program} - ${student.yearLevel} • ${student.gender} • ${student.studentType}'),

        trailing: IconButton(

          icon: const Icon(Icons.arrow_forward_ios, size: 16),

          onPressed: () => _showStudentDetailsDialogFromModel(context, student, avatarColor),

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



  void _showStudentDetailsDialogFromModel(BuildContext context, Student student, Color avatarColor) {

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

                        labelStyle: TextStyle(color: avatarColor, fontWeight: FontWeight.w600),

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

                      _buildInfoRow(Icons.calendar_today, 'Year Level', student.yearLevel),

                      _buildInfoRow(Icons.person, 'Gender', student.gender),

                      _buildInfoRow(Icons.email, 'Email', student.email),

                      _buildInfoRow(Icons.phone, 'Phone', student.phoneNumber ?? 'Not provided'),

                      _buildInfoRow(Icons.location_on, 'Address', student.address ?? 'Not provided'),

                    ],

                  ),

                ),

                Padding(

                  padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),

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

    return FutureBuilder(

      future: _fetchApplicationsOnce(context),

      builder: (context, snapshot) {

        return DefaultTabController(

          length: 3,

          child: Column(

            children: [

              Consumer<AdminApplicationsApiProvider>(

                builder: (context, provider, child) {

                  return Container(

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

                  );

                },

              ),

              Expanded(

                child: Consumer<AdminApplicationsApiProvider>(

                  builder: (context, provider, child) {

                    if (provider.isLoading && provider.pendingEnrollments.isEmpty) {

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

                              onPressed: () => provider.fetchAllEnrollments(),

                              child: const Text('Retry'),

                            ),

                          ],

                        ),

                      );

                    }



                    return TabBarView(

                      children: [

                        _buildApplicationList('PendingReview', provider),

                        _buildApplicationList('Approved', provider),

                        _buildApplicationList('Rejected', provider),

                      ],

                    );

                  },

                ),

              ),

            ],

          ),

        );

      },

    );

  }



  Future<void> _fetchApplicationsOnce(BuildContext context) async {

    final provider = Provider.of<AdminApplicationsApiProvider>(context, listen: false);

    if (provider.pendingEnrollments.isEmpty && 

        provider.approvedEnrollments.isEmpty && 

        provider.rejectedEnrollments.isEmpty) {

      await provider.fetchAllEnrollments();

    }

  }



  Widget _buildApplicationList(String status, AdminApplicationsApiProvider provider) {

    final applications = provider.getEnrollmentsByStatus(status);



    if (applications.isEmpty) {

      return Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(

              status == 'PendingReview' ? Icons.hourglass_empty :

              status == 'Approved' ? Icons.check_circle : Icons.cancel,

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

            return _buildApplicationCard(context, application, status, provider);

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

                _buildInfoRow(Icons.person_outline, 'Student Type', studentType),

                _buildInfoRow(Icons.school, 'Program', programCode),

                _buildInfoRow(Icons.calendar_today, 'Year Level', yearLevel),

                _buildInfoRow(Icons.email, 'Email', application['email']?.toString() ?? 'N/A'),

                _buildInfoRow(Icons.access_time, 'Submitted', _formatDate(application['submittedAt'])),

                if (status == 'Rejected' && application['rejectionReason'] != null)

                  _buildInfoRow(Icons.warning, 'Rejection Reason', application['rejectionReason'].toString()),

                const SizedBox(height: 16),

                if (status == 'PendingReview') ...[

                  Row(

                    children: [

                      Expanded(

                        child: ElevatedButton.icon(

                          onPressed: () => _showApproveDialog(context, application, provider),

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

                          onPressed: () => _showRejectDialog(context, application, provider),

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



  void _showApproveDialog(BuildContext context, Map<String, dynamic> application, AdminApplicationsApiProvider provider) {

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Approve Application'),

        content: Text('Are you sure you want to approve ${application['firstName']} ${application['lastName']}?'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: const Text('Cancel'),

          ),

          ElevatedButton.icon(

            onPressed: () async {

              Navigator.pop(context);

              final success = await provider.approveEnrollment(application['id'].toString());

              if (context.mounted) {

                ScaffoldMessenger.of(context).showSnackBar(

                  SnackBar(

                    content: Text(success ? 'Application approved successfully' : provider.errorMessage ?? 'Failed to approve'),

                    backgroundColor: success ? Colors.green : Colors.red,

                  ),

                );

              }

            },

            icon: const Icon(Icons.check),

            label: const Text('Approve'),

            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),

          ),

        ],

      ),

    );

  }



  void _showRejectDialog(BuildContext context, Map<String, dynamic> application, AdminApplicationsApiProvider provider) {

    final reasonController = TextEditingController();

    

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Reject Application'),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Text('Are you sure you want to reject ${application['firstName']} ${application['lastName']}?'),

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

                  const SnackBar(content: Text('Please enter a rejection reason')),

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

                    content: Text(success ? 'Application rejected' : provider.errorMessage ?? 'Failed to reject'),

                    backgroundColor: success ? Colors.orange : Colors.red,

                  ),

                );

              }

            },

            icon: const Icon(Icons.close),

            label: const Text('Reject'),

            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),

          ),

        ],

      ),

    );

  }



  Widget _buildPlaceholderTab(String title, IconData icon) {

    return Column(

      children: [

        Expanded(

          child: Container(

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

                title: Text(title),

                backgroundColor: Colors.blue[700],

                foregroundColor: Colors.white,

                elevation: 0,

              ),

              body: Center(

                child: Column(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Icon(icon, size: 64, color: Colors.white70),

                    const SizedBox(height: 16),

                    Text(

                      '$title - Coming Soon',

                      style: const TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                        color: Colors.white,

                      ),

                    ),

                  ],

                ),

              ),

            ),

          ),

        ),


      ],

    );

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



  Widget _buildBulletinsTab() {

    return Column(

      children: [

        Expanded(

          child: Scaffold(

            backgroundColor: Colors.transparent,

            appBar: AppBar(

              title: const Text('Bulletin Board'),

              backgroundColor: Colors.blue,

              foregroundColor: Colors.white,

              elevation: 0,

            ),

            body: _buildBulletinsContent(),

          ),

        ),


      ],

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



  Widget _buildBulletinPreviewCard(BuildContext context, Map<String, dynamic> bulletin) {

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

                        items: ['All Students', 'Specific Programs', 'Specific Year Levels']

                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))

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

                                    content: Text('Announcement posted successfully'),

                                    backgroundColor: Colors.green,

                                  ),

                                );

                              } else {

                                ScaffoldMessenger.of(context).showSnackBar(

                                  SnackBar(

                                    content: Text(provider.errorMessage ?? 'Failed to post announcement'),

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

                                  content: Text(newStatus ? 'Bulletin published' : 'Bulletin unpublished'),

                                  backgroundColor: Colors.green,

                                ),

                              );

                            }

                          },

                          icon: Icon(isPublished ? Icons.unpublished : Icons.publish),

                        ),

                        IconButton(

                          onPressed: () async {

                            final confirm = await showDialog<bool>(

                              context: context,

                              builder: (context) => AlertDialog(

                                title: const Text('Delete Bulletin?'),

                                content: const Text('This action cannot be undone.'),

                                actions: [

                                  TextButton(

                                    onPressed: () => Navigator.pop(context, false),

                                    child: const Text('Cancel'),

                                  ),

                                  ElevatedButton(

                                    onPressed: () => Navigator.pop(context, true),

                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

                                    child: const Text('Delete'),

                                  ),

                                ],

                              ),

                            );



                            if (confirm == true && context.mounted) {

                              final success = await provider.deleteBulletin(bulletinId);

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

  int _selectedIndex = 1;



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

          automaticallyImplyLeading: false,

          title: Text(widget.title),

          backgroundColor: Colors.blue[700],

          foregroundColor: Colors.white,

          elevation: 0,

        ),

        body: SingleChildScrollView(

          padding: const EdgeInsets.all(16),

          child: _buildTabContent(widget.tabIndex),

        ),

        bottomNavigationBar: BottomNavigationBar(

          currentIndex: _selectedIndex,

          onTap: (index) {

            if (index == 0) {

              Navigator.of(context).pop();

              return;

            }

            setState(() {

              _selectedIndex = index;

            });

          },

          items: [

            const BottomNavigationBarItem(

              icon: Icon(Icons.home),

              label: 'Home',

            ),

            BottomNavigationBarItem(

              icon: const Icon(Icons.dashboard),

              label: widget.title,

            ),

          ],

          selectedItemColor: Colors.white,

          unselectedItemColor: Colors.white70,

          backgroundColor: Colors.blue[800],

          type: BottomNavigationBarType.fixed,

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



  Widget _buildBulletinContent() {

    return const Center(

      child: Text(

        'Bulletin Management\n\nUse the main dashboard to manage bulletins.',

        textAlign: TextAlign.center,

        style: TextStyle(color: Colors.white, fontSize: 16),

      ),

    );

  }



  Widget _buildBottomNavBar() {

    return const SizedBox.shrink();

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



  Widget _buildBulletinsTab() {

    return Column(

      children: [

        Expanded(

          child: Scaffold(

            backgroundColor: Colors.transparent,

            appBar: AppBar(

              title: const Text('Bulletin Board'),

              backgroundColor: Colors.blue,

              foregroundColor: Colors.white,

              elevation: 0,

            ),

            body: _buildBulletinsContent(),

          ),

        ),


      ],

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

          // Recent Bulletins Preview

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



  Widget _buildBulletinPreviewCard(BuildContext context, Map<String, dynamic> bulletin) {

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



  Widget _buildPlaceholderTab(String title, IconData icon) {

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

          title: Text(title),

          backgroundColor: Colors.blue[700],

          foregroundColor: Colors.white,

          elevation: 0,

        ),

        body: Center(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(icon, size: 64, color: Colors.white70),

              const SizedBox(height: 16),

              Text(

                '$title - Coming Soon',

                style: const TextStyle(

                  fontSize: 20,

                  fontWeight: FontWeight.bold,

                  color: Colors.white,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}
