import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminApplicationDetailsScreen extends StatefulWidget {
  final String applicationId;

  const AdminApplicationDetailsScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<AdminApplicationDetailsScreen> createState() =>
      _AdminApplicationDetailsScreenState();
}

class _AdminApplicationDetailsScreenState
    extends State<AdminApplicationDetailsScreen> {
  static const String _baseUrl = 'https://localhost:7164';

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _application;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Admin token not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/applications/${widget.applicationId}'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _application =
              Map<String, dynamic>.from(jsonDecode(response.body) as Map);
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage =
            'Failed to load application. Status: ${response.statusCode}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading application: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openRequirement(Map<String, dynamic> requirement) async {
    final filePath = requirement['filePath']?.toString();
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.parse('$_baseUrl$filePath');

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file: $uri'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _application == null
                  ? const Center(child: Text('No application data found.'))
                  : RefreshIndicator(
                      onRefresh: _loadApplication,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSection(
                            title: 'Student Information',
                            children: [
                              _buildRow(
                                  'First Name', _application!['firstName']),
                              _buildRow('Last Name', _application!['lastName']),
                              _buildRow('Email', _application!['email']),
                              _buildRow(
                                  'Phone Number', _application!['phoneNumber']),
                              _buildRow('Address', _application!['address']),
                              _buildRow(
                                'Birth Date',
                                _formatDate(_application!['birthDate']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Enrollment Information',
                            children: [
                              _buildRow(
                                  'Student Type', _application!['studentType']),
                              _buildRow(
                                  'Program', _application!['programCode']),
                              _buildRow(
                                  'Year Level', _application!['yearLevel']),
                              _buildRow('Semester', _application!['semester']),
                              _buildRow(
                                'Preferred Schedule',
                                _application!['preferredSchedule'],
                              ),
                              _buildRow('Status', _application!['status']),
                              _buildRow(
                                'Submitted At',
                                _formatDate(_application!['submittedAt']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if ((_application!['guardianFirstName'] != null &&
                                  _application!['guardianFirstName']
                                      .toString()
                                      .trim()
                                      .isNotEmpty) ||
                              (_application!['guardianLastName'] != null &&
                                  _application!['guardianLastName']
                                      .toString()
                                      .trim()
                                      .isNotEmpty))
                            _buildSection(
                              title: 'Guardian Information',
                              children: [
                                _buildRow(
                                  'Guardian First Name',
                                  _application!['guardianFirstName'],
                                ),
                                _buildRow(
                                  'Guardian Last Name',
                                  _application!['guardianLastName'],
                                ),
                                _buildRow(
                                  'Relationship',
                                  _application!['guardianRelationship'],
                                ),
                                _buildRow(
                                  'Contact Number',
                                  _application!['guardianContactNumber'],
                                ),
                                _buildRow(
                                  'Guardian Address',
                                  _application!['guardianAddress'],
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          _buildRequirementsSection(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    final requirements = (_application!['requirements'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Container(
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
          const Text(
            'Requirements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (requirements.isEmpty)
            const Text('No uploaded requirements found.')
          else
            ...requirements.map((requirement) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requirement['requirementType']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'File: ${requirement['originalFileName'] ?? '-'}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Uploaded: ${_formatDate(requirement['createdAt'])}',
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _openRequirement(requirement),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('View File'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final raw = value.toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }
}
