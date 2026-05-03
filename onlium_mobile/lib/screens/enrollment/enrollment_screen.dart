import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../models/enrollment.dart';
import '../../providers/auth_provider.dart';
import 'continuing_enrollment.dart';
import 'new_incoming_enrollment.dart';
import 'transferee_enrollment.dart';

enum EnrollmentStudentType { newIncoming, transferee, continuing }

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  EnrollmentStudentType? _selectedStudentType;

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
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
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
      padding: const EdgeInsets.all(16),
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
            EnrollmentStudentType.newIncoming,
            'New/Incoming Student',
            'For first-time enrollees joining the program.',
            Icons.school,
          ),
          const SizedBox(height: 12),
          _buildTypeCard(
            EnrollmentStudentType.transferee,
            'Transferee Student',
            'For students transferring from another school.',
            Icons.compare_arrows,
          ),
          const SizedBox(height: 12),
          _buildTypeCard(
            EnrollmentStudentType.continuing,
            'Continuing Student',
            'For currently enrolled students continuing their program.',
            Icons.repeat,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    EnrollmentStudentType type,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedStudentType = type;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedStudentType = null;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Change Student Type'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
        Expanded(
          child: _buildEnrollmentFormContent(),
        ),
      ],
    );
  }

  Widget _buildEnrollmentFormContent() {
    switch (_selectedStudentType!) {
      case EnrollmentStudentType.newIncoming:
        return const NewIncomingEnrollment();
      case EnrollmentStudentType.transferee:
        return const TransfereeEnrollment();
      case EnrollmentStudentType.continuing:
        return const ContinuingEnrollment();
    }
  }

  String _getStudentTypeDisplay(EnrollmentStudentType type) {
    switch (type) {
      case EnrollmentStudentType.newIncoming:
        return 'New/Incoming';
      case EnrollmentStudentType.transferee:
        return 'Transferee';
      case EnrollmentStudentType.continuing:
        return 'Continuing';
    }
  }
}

class BaseEnrollmentScreen extends StatefulWidget {
  final EnrollmentStudentType studentType;
  final List<String> requiredDocuments;

  const BaseEnrollmentScreen({
    super.key,
    required this.studentType,
    required this.requiredDocuments,
  });

  @override
  State<BaseEnrollmentScreen> createState() => _BaseEnrollmentScreenState();
}

class _BaseEnrollmentScreenState extends State<BaseEnrollmentScreen> {
  static const String _baseUrl = 'https://localhost:7164';
  // For Android emulator, you may need:
  // static const String _baseUrl = 'http://10.0.2.2:5027';
  // For Windows desktop, you may use:
  // static const String _baseUrl = 'https://localhost:7164';

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
  String? _selectedGender;
  DateTime? _birthDate;
  String? _selectedProgram;
  Schedule _preferredSchedule = Schedule.morning;

  Uint8List? _profilePictureBytes;
  String? _profilePictureName;

  final Map<String, PlatformFile> _uploadedFiles = {};

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

  String _toApiStudentType(EnrollmentStudentType type) {
    switch (type) {
      case EnrollmentStudentType.newIncoming:
        return 'NewIncoming';
      case EnrollmentStudentType.transferee:
        return 'Transferee';
      case EnrollmentStudentType.continuing:
        return 'Continuing';
    }
  }

  String _scheduleToApi(Schedule schedule) {
    switch (schedule) {
      case Schedule.morning:
        return 'Morning';
      case Schedule.afternoon:
        return 'Afternoon';
      case Schedule.evening:
        return 'Evening';
    }
  }

  String _programToCode(String program) {
    if (program.contains('(BSIT)')) return 'BSIT';
    if (program.contains('(BSCS)')) return 'BSCS';
    if (program.contains('(BSBA)')) return 'BSBA';
    if (program.contains('(BSA)')) return 'BSA';
    if (program.contains('(BSHM)')) return 'BSHM';
    return program;
  }

  String _documentToApiRequirementType(String document) {
    switch (document) {
      case 'Report Card':
        return 'ReportCard';
      case 'Good Moral Certificate':
        return 'GoodMoral';
      case 'PSA Birth Certificate':
        return 'PSA';
      case 'Transcript of Records (TOR)':
        return 'TOR';
      case 'Honorable Dismissal':
        return 'HonorableDismissal';
      case 'Clearance':
        return 'Clearance';
      default:
        return document.replaceAll(' ', '');
    }
  }

  bool _requiresGuardianInfo() {
    return widget.studentType == EnrollmentStudentType.newIncoming ||
        widget.studentType == EnrollmentStudentType.transferee;
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _pickProfilePicture() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _profilePictureBytes = result.files.single.bytes!;
        _profilePictureName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadFile(String documentType) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;
      if (file.bytes != null) {
        setState(() {
          _uploadedFiles[documentType] = file;
        });
      }
    }
  }

  Future<void> _uploadRequirementFile({
    required String token,
    required String applicationId,
    required String requirementType,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/Requirements/upload/$applicationId'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['requirementType'] = requirementType;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200 &&
        streamedResponse.statusCode != 201) {
      throw Exception(
        'Upload failed for $requirementType. '
        'Status: ${streamedResponse.statusCode}\n$responseBody',
      );
    }
  }

  Future<void> _submitEnrollment() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_profilePictureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your profile picture'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final allDocumentsUploaded = widget.requiredDocuments.every(
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

    if (_requiresGuardianInfo() &&
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not logged in. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createResponse = await http.post(
        Uri.parse('$_baseUrl/api/Applications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentType': _toApiStudentType(widget.studentType),
          'programCode': _programToCode(_selectedProgram!),
          'yearLevel': 1,
          'semester': 1,
          'preferredSchedule': _scheduleToApi(_preferredSchedule),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'birthDate': _birthDate!.toIso8601String(),
          'gender': _selectedGender,
          'guardianFirstName': _requiresGuardianInfo()
              ? _guardianFirstNameController.text.trim()
              : null,
          'guardianLastName': _requiresGuardianInfo()
              ? _guardianLastNameController.text.trim()
              : null,
          'guardianRelationship': _requiresGuardianInfo()
              ? _guardianRelationship
              : null,
          'guardianContactNumber': _requiresGuardianInfo()
              ? _guardianContactController.text.trim()
              : null,
          'guardianAddress': _requiresGuardianInfo()
              ? _guardianAddressController.text.trim()
              : null,
        }),
      );

      if (createResponse.statusCode == 401) {
        await authProvider.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (createResponse.statusCode != 200 &&
          createResponse.statusCode != 201) {
        throw Exception(
          'Create application failed. Status: ${createResponse.statusCode}\n${createResponse.body}',
        );
      }

      final createdData =
          jsonDecode(createResponse.body) as Map<String, dynamic>;
      final applicationId = createdData['id']?.toString();

      if (applicationId == null || applicationId.isEmpty) {
        throw Exception('Application ID was not returned by the API.');
      }

      await _uploadRequirementFile(
        token: token,
        applicationId: applicationId,
        requirementType: 'Picture',
        bytes: _profilePictureBytes!,
        fileName: _profilePictureName ?? 'picture.jpg',
      );

      for (final doc in widget.requiredDocuments) {
        final file = _uploadedFiles[doc];
        if (file == null || file.bytes == null) continue;

        await _uploadRequirementFile(
          token: token,
          applicationId: applicationId,
          requirementType: _documentToApiRequirementType(doc),
          bytes: file.bytes!,
          fileName: file.name,
        );
      }

      final submitResponse = await http.post(
        Uri.parse('$_baseUrl/api/Applications/$applicationId/submit'),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (submitResponse.statusCode != 200 &&
          submitResponse.statusCode != 204) {
        throw Exception(
          'Submit application failed. Status: ${submitResponse.statusCode}\n${submitResponse.body}',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enrollment submitted successfully! Your requirements will be reviewed by admin.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrollment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 16),
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            if (_requiresGuardianInfo()) ...[
              _buildSectionTitle('Guardian Information'),
              const SizedBox(height: 16),
              _buildGuardianSection(),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('Program Selection'),
            const SizedBox(height: 16),
            _buildProgramSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('1x1 / 2x2 Picture'),
            const SizedBox(height: 16),
            _buildProfilePictureSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Required Documents'),
            const SizedBox(height: 16),
            _buildDocumentsSection(),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitEnrollment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your first name'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: _buildInputDecoration('Last Name', Icons.person),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your last name'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration('Phone Number', Icons.phone),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your phone number'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: _buildInputDecoration('Address', Icons.home),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter your address'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            isExpanded: true,
            decoration: _buildInputDecoration('Gender', Icons.person_outline),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) => value == null || value.isEmpty
                ? 'Please select your gender'
                : null,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectBirthDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
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
                    if (_requiresGuardianInfo() &&
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
                    if (_requiresGuardianInfo() &&
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
            isExpanded: true,
            decoration: _buildInputDecoration(
              'Relationship to Student',
              Icons.family_restroom,
            ),
            items: const [
              DropdownMenuItem(value: 'Mother', child: Text('Mother', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Father', child: Text('Father', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Guardian', child: Text('Guardian', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Aunt', child: Text('Aunt', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'Uncle', child: Text('Uncle', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(
                value: 'Grandmother',
                child: Text('Grandmother', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'Grandfather',
                child: Text('Grandfather', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(value: 'Other', child: Text('Other', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (value) {
              setState(() {
                _guardianRelationship = value;
              });
            },
            validator: (value) {
              if (_requiresGuardianInfo() && (value == null || value.isEmpty)) {
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
              if (_requiresGuardianInfo() && (value == null || value.isEmpty)) {
                return 'Please enter guardian contact number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _guardianAddressController,
            decoration: _buildInputDecoration('Guardian Address', Icons.home),
            validator: (value) {
              if (_requiresGuardianInfo() && (value == null || value.isEmpty)) {
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
            isExpanded: true,
            decoration: _buildInputDecoration('Select Program', Icons.school),
            items: _availablePrograms.map((program) {
              return DropdownMenuItem<String>(
                value: program,
                child: Text(program, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProgram = value;
              });
            },
            validator: (value) => value == null || value.isEmpty
                ? 'Please select a program'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Schedule>(
            value: _preferredSchedule,
            isExpanded: true,
            decoration: _buildInputDecoration(
              'Preferred Schedule',
              Icons.schedule,
            ),
            items: Schedule.values.map((schedule) {
              return DropdownMenuItem<Schedule>(
                value: schedule,
                child: Text(_getScheduleDisplay(schedule)),
              );
            }).toList(),
            onChanged: (value) {
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
          if (_profilePictureBytes != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: MemoryImage(_profilePictureBytes!),
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.photo, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickProfilePicture,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload 1x1 / 2x2 Picture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
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
          final uploaded = _uploadedFiles.containsKey(document);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: uploaded ? Colors.green[50] : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    uploaded ? Icons.check_circle : Icons.upload_file,
                    color: uploaded ? Colors.green : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      uploaded ? '$document - Uploaded' : document,
                      style: TextStyle(
                        color: uploaded ? Colors.green[700] : Colors.black87,
                        fontWeight: uploaded
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!uploaded)
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
