import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../models/enrollment.dart';
import 'new_incoming_enrollment.dart';
import 'transferee_enrollment.dart';
import 'continuing_enrollment.dart';

class EnrollmentScreen extends StatefulWidget {
  EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  StudentType? _selectedStudentType;

  @override
  Widget build(BuildContext context) {
    final title = _selectedStudentType == null
        ? 'Select Enrollment Type'
        : '${_getStudentTypeDisplay(_selectedStudentType!)} Enrollment';

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
            title: Text(title),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: _selectedStudentType == null
              ? _buildTypeSelection()
              : _buildEnrollmentForm(),
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your student type before continuing to enrollment.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildTypeCard(
            StudentType.newIncoming,
            'New/Incoming Student',
            'For first-time enrollees joining the program.',
            Icons.school,
          ),
          const SizedBox(height: 12),
          _buildTypeCard(
            StudentType.transferee,
            'Transferee Student',
            'For students transferring from another school.',
            Icons.compare_arrows,
          ),
          const SizedBox(height: 12),
          _buildTypeCard(
            StudentType.continuing,
            'Continuing Student',
            'For currently enrolled students continuing their program.',
            Icons.repeat,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    StudentType type,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _selectedStudentType = type;
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue[700],
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentForm() {
    Widget enrollmentScreen;

    switch (_selectedStudentType!) {
      case StudentType.newIncoming:
        enrollmentScreen = const NewIncomingEnrollment();
        break;
      case StudentType.transferee:
        enrollmentScreen = const TransfereeEnrollment();
        break;
      case StudentType.continuing:
        enrollmentScreen = const ContinuingEnrollment();
        break;
    }

    return enrollmentScreen;
  }

  String _getStudentTypeDisplay(StudentType type) {
    switch (type) {
      case StudentType.newIncoming:
        return 'New/Incoming';
      case StudentType.transferee:
        return 'Transferee';
      case StudentType.continuing:
        return 'Continuing';
    }
  }
}

class BaseEnrollmentScreen extends StatefulWidget {
  final StudentType studentType;
  final List<String> requiredDocuments;
  final Widget child;

  const BaseEnrollmentScreen({
    super.key,
    required this.studentType,
    required this.requiredDocuments,
    required this.child,
  });

  @override
  State<BaseEnrollmentScreen> createState() => _BaseEnrollmentScreenState();
}

class _BaseEnrollmentScreenState extends State<BaseEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _guardianFirstNameController = TextEditingController();
  final _guardianLastNameController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _guardianAddressController = TextEditingController();
  String? _guardianRelationship;
  DateTime? _birthDate;
  String? _selectedProgram;
  Schedule _preferredSchedule = Schedule.morning;
  String? _profilePicturePath;
  Map<String, String> _uploadedFiles = {};
  bool _isLoading = false;

  final List<String> _availablePrograms = [
    'Bachelor of Science in Information Technology (BSIT)',
    'Bachelor of Science in Computer Science (BSCS)',
    'Bachelor of Science in Business Administration (BSBA)',
    'Bachelor of Science in Accountancy (BSA)',
    'Bachelor of Science in Hospitality Management (BSHM)',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _guardianFirstNameController.dispose();
    _guardianLastNameController.dispose();
    _guardianContactController.dispose();
    _guardianAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profilePicturePath = image.path;
      });
    }
  }

  Future<void> _uploadFile(String documentType) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _uploadedFiles[documentType] = result.files.single.path!;
      });
    }
  }

  Future<void> _submitEnrollment() async {
    if (_formKey.currentState!.validate()) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your birth date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedProgram == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a program'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_profilePicturePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your profile picture'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if all required documents are uploaded
      bool allDocumentsUploaded = widget.requiredDocuments.every(
        (doc) => _uploadedFiles.containsKey(doc),
      );

      if (!allDocumentsUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload all required documents'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (widget.studentType == StudentType.newIncoming &&
          (_guardianFirstNameController.text.trim().isEmpty ||
              _guardianLastNameController.text.trim().isEmpty ||
              _guardianContactController.text.trim().isEmpty ||
              _guardianAddressController.text.trim().isEmpty ||
              _guardianRelationship == null ||
              _guardianRelationship!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all guardian information'),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 16),
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),

            // Guardian Information Section (only for new incoming students)
            if (widget.studentType == StudentType.newIncoming) ...[
              _buildSectionTitle('Guardian Information'),
              const SizedBox(height: 16),
              _buildGuardianSection(),
              const SizedBox(height: 24),
            ],

            // Program Selection Section
            _buildSectionTitle('Program Selection'),
            const SizedBox(height: 16),
            _buildProgramSection(),
            const SizedBox(height: 24),

            // Photo Section
            _buildSectionTitle('1x1 / 2x2 Picture'),
            const SizedBox(height: 16),
            _buildProfilePictureSection(),
            const SizedBox(height: 24),

            // Required Documents Section
            _buildSectionTitle('Required Documents'),
            const SizedBox(height: 16),
            _buildDocumentsSection(),
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

  Widget _buildPersonalInfoSection() {
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: _buildInputDecoration('First Name', Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: _buildInputDecoration('Last Name', Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration('Phone Number', Icons.phone),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            maxLines: 1,
            decoration: _buildInputDecoration('Address', Icons.home),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectBirthDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate != null
                        ? 'Birth Date: ${_birthDate!.toString().split(' ')[0]}'
                        : 'Select Birth Date',
                    style: TextStyle(
                      color: _birthDate != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianSection() {
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _guardianFirstNameController,
                  decoration: _buildInputDecoration(
                    'Guardian First Name',
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (widget.studentType == StudentType.newIncoming &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter guardian first name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _guardianLastNameController,
                  decoration: _buildInputDecoration(
                    'Guardian Last Name',
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (widget.studentType == StudentType.newIncoming &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter guardian last name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _guardianRelationship,
            decoration: _buildInputDecoration(
              'Relationship to Student',
              Icons.family_restroom,
            ),
            items: const [
              DropdownMenuItem(value: 'Mother', child: Text('Mother')),
              DropdownMenuItem(value: 'Father', child: Text('Father')),
              DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
              DropdownMenuItem(value: 'Aunt', child: Text('Aunt')),
              DropdownMenuItem(value: 'Uncle', child: Text('Uncle')),
              DropdownMenuItem(
                value: 'Grandmother',
                child: Text('Grandmother'),
              ),
              DropdownMenuItem(
                value: 'Grandfather',
                child: Text('Grandfather'),
              ),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (String? value) {
              setState(() {
                _guardianRelationship = value;
              });
            },
            validator: (value) {
              if (widget.studentType == StudentType.newIncoming &&
                  (value == null || value.isEmpty)) {
                return 'Please select relationship to student';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guardianContactController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration(
              'Guardian Contact Number',
              Icons.phone,
            ),
            validator: (value) {
              if (widget.studentType == StudentType.newIncoming &&
                  (value == null || value.isEmpty)) {
                return 'Please enter guardian contact number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guardianAddressController,
            maxLines: 1,
            decoration: _buildInputDecoration('Guardian Address', Icons.home),
            validator: (value) {
              if (widget.studentType == StudentType.newIncoming &&
                  (value == null || value.isEmpty)) {
                return 'Please enter guardian address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgramSection() {
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
            value: _selectedProgram,
            decoration: _buildInputDecoration('Select Program', Icons.school),
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
            decoration: _buildInputDecoration(
              'Preferred Schedule',
              Icons.schedule,
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

  Widget _buildProfilePictureSection() {
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
          if (_profilePicturePath != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(_profilePicturePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.photo, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickProfilePicture,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload 1x1 / 2x2 Picture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload a clear 1x1 or 2x2 photo with a white background.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
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
        children: widget.requiredDocuments.map((document) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: _uploadedFiles.containsKey(document)
                    ? Colors.green[50]
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    _uploadedFiles.containsKey(document)
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color: _uploadedFiles.containsKey(document)
                        ? Colors.green
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploadedFiles.containsKey(document)
                          ? '$document - Uploaded'
                          : document,
                      style: TextStyle(
                        color: _uploadedFiles.containsKey(document)
                            ? Colors.green[700]
                            : Colors.black87,
                        fontWeight: _uploadedFiles.containsKey(document)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!_uploadedFiles.containsKey(document))
                    ElevatedButton(
                      onPressed: () => _uploadFile(document),
                      child: const Text('Upload'),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[50],
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
}
