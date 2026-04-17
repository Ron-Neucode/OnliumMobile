import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../models/enrollment.dart';

class StudyLoadScreen extends StatefulWidget {
  const StudyLoadScreen({super.key});

  @override
  State<StudyLoadScreen> createState() => _StudyLoadScreenState();
}

class _StudyLoadScreenState extends State<StudyLoadScreen> {
  bool _isEnrolled = false;
  String _selectedYear = 'First Year';
  List<Subject> _subjects = [];

  final List<String> _years = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  final Map<String, List<Subject>> _subjectsByYear = {
    'First Year': [
      Subject(
        code: 'MATH101',
        name: 'College Algebra',
        schedule: 'MWF 8:00-9:00 AM',
        instructor: 'Dr. Smith',
        units: 3,
      ),
      Subject(
        code: 'ENG101',
        name: 'English Communication',
        schedule: 'TTH 10:00-11:30 AM',
        instructor: 'Prof. Johnson',
        units: 3,
      ),
      Subject(
        code: 'CS101',
        name: 'Introduction to Computer Science',
        schedule: 'MWF 1:00-2:00 PM',
        instructor: 'Engr. Davis',
        units: 3,
      ),
      Subject(
        code: 'PE101',
        name: 'Physical Education',
        schedule: 'TTH 2:00-3:30 PM',
        instructor: 'Coach Wilson',
        units: 2,
      ),
    ],
    'Second Year': [
      Subject(
        code: 'MATH201',
        name: 'Calculus I',
        schedule: 'MWF 9:00-10:00 AM',
        instructor: 'Dr. Brown',
        units: 4,
      ),
      Subject(
        code: 'CS201',
        name: 'Data Structures',
        schedule: 'TTH 8:00-9:30 AM',
        instructor: 'Prof. Miller',
        units: 3,
      ),
      Subject(
        code: 'ENG201',
        name: 'Technical Writing',
        schedule: 'MWF 2:00-3:00 PM',
        instructor: 'Dr. Taylor',
        units: 3,
      ),
      Subject(
        code: 'PHYS201',
        name: 'Physics I',
        schedule: 'TTH 1:00-2:30 PM',
        instructor: 'Prof. Anderson',
        units: 3,
      ),
    ],
    'Third Year': [
      Subject(
        code: 'CS301',
        name: 'Database Systems',
        schedule: 'MWF 10:00-11:00 AM',
        instructor: 'Dr. Martinez',
        units: 3,
      ),
      Subject(
        code: 'CS302',
        name: 'Software Engineering',
        schedule: 'TTH 9:00-10:30 AM',
        instructor: 'Prof. Garcia',
        units: 3,
      ),
      Subject(
        code: 'MATH301',
        name: 'Discrete Mathematics',
        schedule: 'MWF 1:00-2:00 PM',
        instructor: 'Dr. Rodriguez',
        units: 3,
      ),
      Subject(
        code: 'NET301',
        name: 'Computer Networks',
        schedule: 'TTH 2:00-3:30 PM',
        instructor: 'Engr. Lopez',
        units: 3,
      ),
    ],
    'Fourth Year': [
      Subject(
        code: 'CS401',
        name: 'Machine Learning',
        schedule: 'MWF 8:00-9:00 AM',
        instructor: 'Dr. Chen',
        units: 3,
      ),
      Subject(
        code: 'CS402',
        name: 'Web Development',
        schedule: 'TTH 10:00-11:30 AM',
        instructor: 'Prof. Kumar',
        units: 3,
      ),
      Subject(
        code: 'CS403',
        name: 'Capstone Project',
        schedule: 'MWF 2:00-4:00 PM',
        instructor: 'Dr. Wilson',
        units: 6,
      ),
      Subject(
        code: 'ETH401',
        name: 'Professional Ethics',
        schedule: 'TTH 1:00-2:30 PM',
        instructor: 'Prof. Thompson',
        units: 2,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEnrollmentStatus();
    });
  }

  void _checkEnrollmentStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enrollmentProvider = Provider.of<EnrollmentProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.currentUser;

    bool isEnrolled = false;
    if (currentUser != null) {
      final userEnrollments = enrollmentProvider.getEnrollmentsByUserId(
        currentUser.id,
      );
      isEnrolled = userEnrollments.any(
        (enrollment) => enrollment.status == EnrollmentStatus.approved,
      );
    }

    setState(() {
      _isEnrolled = isEnrolled;
      _subjects = isEnrolled ? _subjectsByYear[_selectedYear] ?? [] : [];
    });
  }

  void _loadSubjects() {
    setState(() {
      _subjects = _subjectsByYear[_selectedYear] ?? [];
    });
  }

  bool _hasScheduleConflict(Subject subject1, Subject subject2) {
    // Simple schedule conflict detection
    if (subject1.schedule == subject2.schedule) {
      return true;
    }

    // Extract time ranges and check for overlaps
    final time1 = _extractTimeRange(subject1.schedule);
    final time2 = _extractTimeRange(subject2.schedule);

    if (time1 != null && time2 != null) {
      return _timeRangesOverlap(time1, time2);
    }

    return false;
  }

  Map<String, String>? _extractTimeRange(String schedule) {
    // Extract time range from schedule string
    // Example: "MWF 8:00-9:00 AM" -> {"start": "8:00 AM", "end": "9:00 AM"}
    final regex = RegExp(r'(\d{1,2}:\d{2}\s[AP]M)-(\d{1,2}:\d{2}\s[AP]M)');
    final match = regex.firstMatch(schedule);

    if (match != null) {
      return {'start': match.group(1)!, 'end': match.group(2)!};
    }

    return null;
  }

  bool _timeRangesOverlap(
    Map<String, String> range1,
    Map<String, String> range2,
  ) {
    // Simple time overlap check
    // In a real app, this would be more sophisticated
    return range1['start'] == range2['start'] || range1['end'] == range2['end'];
  }

  void _checkForConflicts() {
    List<String> conflicts = [];

    for (int i = 0; i < _subjects.length; i++) {
      for (int j = i + 1; j < _subjects.length; j++) {
        if (_hasScheduleConflict(_subjects[i], _subjects[j])) {
          conflicts.add(
            'Conflict: ${_subjects[i].code} and ${_subjects[j].code}',
          );
        }
      }
    }

    if (conflicts.isNotEmpty) {
      _showConflictDialog(conflicts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No schedule conflicts found!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showConflictDialog(List<String> conflicts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Conflicts Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following schedule conflicts were detected:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...conflicts.map(
              (conflict) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(conflict)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please consult with the admin to resolve these conflicts.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _contactAdmin();
            },
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
  }

  void _contactAdmin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin contact request sent!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3F7ED8), Color(0xFF8EC7FF), Color(0xFFD6ECFF)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Study Load'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: !_isEnrolled ? _buildNotEnrolledView() : _buildEnrolledView(),
        ),
      ),
    );
  }

  Widget _buildNotEnrolledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 80, color: Colors.orange[600]),
            const SizedBox(height: 20),
            Text(
              'Not Enrolled',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You need to complete your enrollment first before viewing your study load.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.app_registration),
              label: const Text('Go to Enrollment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Year',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Academic Year',
                    prefixIcon: const Icon(Icons.school),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: _years.map((String year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                    _loadSubjects();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkForConflicts,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Check Conflicts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Study load viewed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subjects List
          const Text(
            'Subjects',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._subjects.map((subject) => _buildSubjectCard(subject)).toList(),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                      subject.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      subject.name,
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
                  '${subject.units} units',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                subject.schedule,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                subject.instructor,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
