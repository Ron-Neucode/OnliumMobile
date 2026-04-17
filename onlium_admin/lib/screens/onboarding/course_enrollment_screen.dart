import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/enrollment_management_provider.dart';

class CourseEnrollmentScreen extends StatefulWidget {
  const CourseEnrollmentScreen({super.key});

  @override
  State<CourseEnrollmentScreen> createState() => _CourseEnrollmentScreenState();
}

class _CourseEnrollmentScreenState extends State<CourseEnrollmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Course Enrollment Management'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<EnrollmentManagementProvider>(
        builder: (context, provider, child) {
          final approvedEnrollments = provider.getEnrollmentsByStatus(EnrollmentStatus.approved);
          
          if (approvedEnrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No students available for course enrollment',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedEnrollments.length,
            itemBuilder: (context, index) {
              return _buildCourseCard(approvedEnrollments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(EnrollmentRequest enrollment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enrollment.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(enrollment.studentType.toString().split('.')[1]),
                      backgroundColor: Colors.orange[100],
                      labelStyle: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${enrollment.program}',
                  style: TextStyle(color: Colors.orange[600]),
                ),
                Text(
                  'Student ID: STU-${DateTime.now().year}-${enrollment.id.substring(0, 6).toUpperCase()}',
                  style: TextStyle(color: Colors.orange[600]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course Enrollment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Units: 18/24',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCourseItem('Mathematics 101', '3 units', 'Core', true),
                _buildCourseItem('English 101', '3 units', 'Core', true),
                _buildCourseItem('Science 101', '3 units', 'Core', true),
                _buildCourseItem('Computer Fundamentals', '3 units', 'Core', true),
                _buildCourseItem('Physical Education', '2 units', 'PE', false),
                _buildCourseItem('Arts & Humanities', '3 units', 'Elective', false),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Student needs 6 more units to complete enrollment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCourseSelectionDialog(enrollment),
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Add Courses'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEnrollmentSummary(enrollment),
                        icon: const Icon(Icons.list),
                        label: const Text('Summary'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(String courseName, String units, String type, bool isEnrolled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isEnrolled ? Colors.green[50] : Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            isEnrolled ? Icons.check_circle : Icons.circle_outlined,
            color: isEnrolled ? Colors.green : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnrolled ? Colors.green[700] : Colors.black87,
                  ),
                ),
                Text(
                  '$units  $type',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isEnrolled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Enrolled',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course added to enrollment list'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Add'),
            ),
        ],
      ),
    );
  }

  void _showCourseSelectionDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Courses: ${enrollment.studentName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Available Courses:'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildSelectableCourse('Physical Education', '2 units', 'PE'),
                    _buildSelectableCourse('Arts & Humanities', '3 units', 'Elective'),
                    _buildSelectableCourse('Business Math', '3 units', 'Elective'),
                    _buildSelectableCourse('Environmental Science', '3 units', 'Core'),
                  ],
                ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Courses added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
            child: const Text('Add Selected'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableCourse(String courseName, String units, String type) {
    bool isSelected = false;
    return StatefulBuilder(
      builder: (context, setState) => CheckboxListTile(
        title: Text(courseName),
        subtitle: Text('$units  $type'),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            isSelected = value!;
          });
        },
        activeColor: Colors.orange[700],
      ),
    );
  }

  void _showEnrollmentSummary(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enrollment Summary: ${enrollment.studentName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryItem('Student ID', 'STU-${DateTime.now().year}-${enrollment.id.substring(0, 6).toUpperCase()}'),
              _buildSummaryItem('Program', enrollment.program),
              _buildSummaryItem('Semester', '1st Semester 2024-2025'),
              const SizedBox(height: 12),
              const Text('Enrolled Courses:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSummaryCourse('Mathematics 101', '3 units'),
              _buildSummaryCourse('English 101', '3 units'),
              _buildSummaryCourse('Science 101', '3 units'),
              _buildSummaryCourse('Computer Fundamentals', '3 units'),
              const Divider(),
              _buildSummaryItem('Total Units', '12 units'),
              _buildSummaryItem('Status', 'Incomplete - 6 more units needed'),
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
                const SnackBar(
                  content: Text('Enrollment summary sent to student email'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
            child: const Text('Send to Student'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSummaryCourse(String courseName, String units) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 16),
      child: Text('  $courseName - $units'),
    );
  }
}
