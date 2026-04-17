import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/enrollment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';

class ContinuingEnrollment extends StatefulWidget {
  const ContinuingEnrollment({super.key});

  @override
  State<ContinuingEnrollment> createState() => _ContinuingEnrollmentState();
}

class _ContinuingEnrollmentState extends State<ContinuingEnrollment> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedYear;
  String? _selectedProgram;
  Schedule _preferredSchedule = Schedule.morning;
  String? _clearancePath;
  bool _isLoading = false;

  final List<String> _availableYears = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  final List<String> _availablePrograms = [
    'Bachelor of Science in Information Technology (BSIT)',
    'Bachelor of Science in Computer Science (BSCS)',
    'Bachelor of Science in Business Administration (BSBA)',
    'Bachelor of Science in Accountancy (BSA)',
    'Bachelor of Science in Hospitality Management (BSHM)',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check Personal Information Section
            _buildSectionTitle('Check Personal Information'),
            const SizedBox(height: 16),
            _buildPersonalInfoCheck(),
            const SizedBox(height: 24),

            // Clearance Upload Section
            _buildSectionTitle('Clearance Upload'),
            const SizedBox(height: 16),
            _buildClearanceSection(),
            const SizedBox(height: 24),

            // Program and Year Selection Section
            _buildSectionTitle('Program and Year Selection'),
            const SizedBox(height: 16),
            _buildProgramYearSection(),
            const SizedBox(height: 32),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitEnrollment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Enrollment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPersonalInfoCheck() {
    return Container(
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
        children: [
          const Text(
            'Please verify your personal information is correct before proceeding.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPersonalInfoDialog();
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Personal Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEditPersonalInfoDialog();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceSection() {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You cannot enroll without your clearance. Please upload your clearance to continue.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_clearancePath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Clearance uploaded successfully',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _clearancePath = null;
                      });
                    },
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _uploadClearance,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Clearance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgramYearSection() {
    return Container(
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
        children: [
          DropdownButtonFormField<String>(
            value: _selectedYear,
            decoration: InputDecoration(
              labelText: 'Select Year',
              prefixIcon: const Icon(Icons.school),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _availableYears.map((String year) {
              return DropdownMenuItem<String>(value: year, child: Text(year));
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedYear = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProgram,
            decoration: InputDecoration(
              labelText: 'Select Program',
              prefixIcon: const Icon(Icons.book),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _availablePrograms.map((String program) {
              return DropdownMenuItem<String>(
                value: program,
                child: Text(program),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedProgram = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a program';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Schedule>(
            value: _preferredSchedule,
            decoration: InputDecoration(
              labelText: 'Preferred Schedule',
              prefixIcon: const Icon(Icons.schedule),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: Schedule.values.map((Schedule schedule) {
              return DropdownMenuItem<Schedule>(
                value: schedule,
                child: Text(_getScheduleDisplay(schedule)),
              );
            }).toList(),
            onChanged: (Schedule? value) {
              setState(() {
                _preferredSchedule = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadClearance() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _clearancePath = result.files.single.path!;
      });
    }
  }

  Future<void> _submitEnrollment() async {
    if (_formKey.currentState!.validate()) {
      if (_clearancePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your clearance'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enrollment submitted successfully! Your requirements will be reviewed by admin.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  void _showPersonalInfoDialog() {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${currentUser?.fullName ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Email: ${currentUser?.email ?? 'Not available'}'),
            const SizedBox(height: 8),
            Text(
              'Student Status: ${currentUser != null ? _getStudentStatusDisplay(currentUser.id) : 'Not available'}',
            ),
            const SizedBox(height: 8),
            const Text('Phone: 123-456-7890'),
            const SizedBox(height: 8),
            const Text('Address: 123 Main St, City'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditPersonalInfoDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final nameController = TextEditingController(
      text: currentUser?.fullName ?? '',
    );
    final emailController = TextEditingController(
      text: currentUser?.email ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal Information'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                if (currentUser != null) {
                  final updatedUser = currentUser.copyWith(
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                  );
                  await authProvider.updateCurrentUser(updatedUser);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Personal information updated successfully.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getScheduleDisplay(Schedule schedule) {
    switch (schedule) {
      case Schedule.morning:
        return 'Morning';
      case Schedule.afternoon:
        return 'Afternoon';
      case Schedule.evening:
        return 'Evening';
    }
  }

  String _getStudentStatusDisplay(String userId) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(
      context,
      listen: false,
    );
    final userEnrollments = enrollmentProvider.getEnrollmentsByUserId(userId);
    final isEnrolled = userEnrollments.any(
      (enrollment) =>
          enrollment.status == EnrollmentStatus.approved ||
          enrollment.status == EnrollmentStatus.completed,
    );
    return isEnrolled ? 'Enrolled' : 'Not yet enrolled';
  }
}
