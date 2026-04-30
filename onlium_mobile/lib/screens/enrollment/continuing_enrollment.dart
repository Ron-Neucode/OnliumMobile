import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../models/enrollment.dart';
import '../../providers/auth_provider.dart';

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
  String? _selectedGender;

  Uint8List? _clearanceBytes;
  String? _clearanceFileName;

  bool _isLoading = false;

  final List<String> _availableYears = const [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  final List<String> _availablePrograms = const [
    'Bachelor of Science in Information Technology (BSIT)',
    'Bachelor of Science in Computer Science (BSCS)',
    'Bachelor of Science in Business Administration (BSBA)',
    'Bachelor of Science in Accountancy (BSA)',
    'Bachelor of Science in Hospitality Management (BSHM)',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Check Personal Information'),
            const SizedBox(height: 16),
            _buildPersonalInfoCheck(),
            const SizedBox(height: 24),

            _buildSectionTitle('Clearance Upload'),
            const SizedBox(height: 16),
            _buildClearanceSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('Program and Year Selection'),
            const SizedBox(height: 16),
            _buildProgramYearSection(),
            const SizedBox(height: 32),

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
                  onPressed: _showPersonalInfoDialog,
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
                  onPressed: _showEditPersonalInfoDialog,
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
          if (_clearanceBytes != null)
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
                  Expanded(
                    child: Text(
                      _clearanceFileName ?? 'Clearance uploaded successfully',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _clearanceBytes = null;
                        _clearanceFileName = null;
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
            items: _availableYears.map((year) {
              return DropdownMenuItem<String>(value: year, child: Text(year));
            }).toList(),
            onChanged: (value) {
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
            items: _availablePrograms.map((program) {
              return DropdownMenuItem<String>(
                value: program,
                child: Text(program),
              );
            }).toList(),
            onChanged: (value) {
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

  Future<void> _uploadClearance() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _clearanceBytes = result.files.single.bytes!;
        _clearanceFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadRequirementFile({
    required String token,
    required String applicationId,
    required String requirementType,
    required Uint8List bytes,
    required String fileName,
  }) async {
    const baseUrl = 'https://localhost:7164';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/Requirements/upload/$applicationId'),
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_clearanceBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your clearance'),
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

    if ((authProvider.firstName ?? '').trim().isEmpty ||
        (authProvider.lastName ?? '').trim().isEmpty ||
        (authProvider.phoneNumber ?? '').trim().isEmpty ||
        (authProvider.address ?? '').trim().isEmpty ||
        authProvider.birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete your personal information first using Edit Info.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const baseUrl = 'https://localhost:7164';

      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/Applications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentType': 'Continuing',
          'programCode': _programToCode(_selectedProgram!),
          'yearLevel': _yearToLevel(_selectedYear!),
          'semester': 1,
          'preferredSchedule': _scheduleToApi(_preferredSchedule),
          'firstName': authProvider.firstName!.trim(),
          'lastName': authProvider.lastName!.trim(),
          'phoneNumber': authProvider.phoneNumber!.trim(),
          'address': authProvider.address!.trim(),
          'birthDate': authProvider.birthDate!.toIso8601String(),
          'gender': _selectedGender,
          'guardianFirstName': null,
          'guardianLastName': null,
          'guardianRelationship': null,
          'guardianContactNumber': null,
          'guardianAddress': null,
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
          'Create application failed. '
          'Status: ${createResponse.statusCode}\n${createResponse.body}',
        );
      }

      final createdData =
          jsonDecode(createResponse.body) as Map<String, dynamic>;
      final applicationId =
          createdData['id']?.toString() ??
          createdData['applicationId']?.toString();

      if (applicationId == null || applicationId.isEmpty) {
        throw Exception('Application ID was not returned by the API.');
      }

      await _uploadRequirementFile(
        token: token,
        applicationId: applicationId,
        requirementType: 'Clearance',
        bytes: _clearanceBytes!,
        fileName: _clearanceFileName ?? 'clearance.pdf',
      );

      final submitResponse = await http.post(
        Uri.parse('$baseUrl/api/Applications/$applicationId/submit'),
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (submitResponse.statusCode == 401) {
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

      if (submitResponse.statusCode != 200 &&
          submitResponse.statusCode != 204) {
        throw Exception(
          'Submit application failed. '
          'Status: ${submitResponse.statusCode}\n${submitResponse.body}',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Continuing enrollment submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Continuing enrollment failed: $e'),
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

  void _showPersonalInfoDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name: ${authProvider.fullName ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Email: ${authProvider.email ?? 'Not available'}'),
            const SizedBox(height: 8),
            Text('First Name: ${authProvider.firstName ?? '-'}'),
            const SizedBox(height: 8),
            Text('Last Name: ${authProvider.lastName ?? '-'}'),
            const SizedBox(height: 8),
            Text('Phone Number: ${authProvider.phoneNumber ?? '-'}'),
            const SizedBox(height: 8),
            Text('Address: ${authProvider.address ?? '-'}'),
            const SizedBox(height: 8),
            Text(
              'Birth Date: ${authProvider.birthDate != null ? authProvider.birthDate!.toString().split(' ')[0] : '-'}',
            ),
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

  Future<void> _showEditPersonalInfoDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final firstNameController = TextEditingController(
      text: authProvider.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: authProvider.lastName ?? '',
    );
    final phoneNumberController = TextEditingController(
      text: authProvider.phoneNumber ?? '',
    );
    final addressController = TextEditingController(
      text: authProvider.address ?? '',
    );

    DateTime? selectedBirthDate = authProvider.birthDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Personal Information'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedBirthDate ??
                              DateTime.now().subtract(
                                const Duration(days: 365 * 18),
                              ),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365 * 100),
                          ),
                          lastDate: DateTime.now().subtract(
                            const Duration(days: 365 * 15),
                          ),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedBirthDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedBirthDate != null
                              ? 'Birth Date: ${selectedBirthDate!.toString().split(' ')[0]}'
                              : 'Select Birth Date',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (firstNameController.text.trim().isEmpty ||
                        lastNameController.text.trim().isEmpty ||
                        phoneNumberController.text.trim().isEmpty ||
                        addressController.text.trim().isEmpty ||
                        selectedBirthDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete all fields.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final success = await authProvider.updateProfile(
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      phoneNumber: phoneNumberController.text.trim(),
                      address: addressController.text.trim(),
                      birthDate: selectedBirthDate!,
                    );

                    if (!mounted) return;

                    if (success) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'Profile update failed.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
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

  int _yearToLevel(String year) {
    switch (year) {
      case 'First Year':
        return 1;
      case 'Second Year':
        return 2;
      case 'Third Year':
        return 3;
      case 'Fourth Year':
        return 4;
      default:
        return 1;
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
}
