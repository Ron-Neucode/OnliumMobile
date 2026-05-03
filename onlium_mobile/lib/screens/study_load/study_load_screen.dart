import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class StudyLoadScreen extends StatefulWidget {
  const StudyLoadScreen({super.key});

  @override
  State<StudyLoadScreen> createState() => _StudyLoadScreenState();
}

class _StudyLoadScreenState extends State<StudyLoadScreen> {
  static const String _baseUrl = 'https://localhost:7164';

  final List<String> _programs = ['BSIT', 'BSCS', 'BSBA', 'BSA', 'BSHM'];

  final List<Map<String, dynamic>> _yearLevels = [
    {'label': '1st Year', 'value': 1},
    {'label': '2nd Year', 'value': 2},
    {'label': '3rd Year', 'value': 3},
    {'label': '4th Year', 'value': 4},
  ];

  final List<Map<String, dynamic>> _semesters = [
    {'label': '1st Semester', 'value': 1},
    {'label': '2nd Semester', 'value': 2},
    {'label': 'Summer', 'value': 3},
  ];

  String _selectedProgram = 'BSIT';
  int _selectedYearLevel = 1;
  int _selectedSemester = 1;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchStudyLoad();
  }

  Future<void> _fetchStudyLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'You are not logged in.';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('$_baseUrl/api/StudyLoads').replace(
        queryParameters: {
          'programCode': _selectedProgram,
          'yearLevel': _selectedYearLevel.toString(),
          'semester': _selectedSemester.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;

        setState(() {
          _subjects = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage =
            'Failed to load study load. Status: ${response.statusCode}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading study load: $e';
        _isLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double get _grandTotalUnits {
    return _subjects.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['totalUnits']),
    );
  }

  Widget _buildNotSignedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.orange[700]),
            const SizedBox(height: 20),
            Text(
              'Sign In Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in first before viewing your study load.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(AuthProvider authProvider) {
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
            'Student: ${authProvider.fullName ?? 'Unknown'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Email: ${authProvider.email ?? 'Not available'}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Program: $_selectedProgram',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
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
            'Filter Study Load',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedProgram,
            decoration: InputDecoration(
              labelText: 'Program',
              prefixIcon: const Icon(Icons.school),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _programs.map((program) {
              return DropdownMenuItem<String>(
                value: program,
                child: Text(program),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedProgram = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedYearLevel,
            decoration: InputDecoration(
              labelText: 'Year Level',
              prefixIcon: const Icon(Icons.badge),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _yearLevels.map((year) {
              return DropdownMenuItem<int>(
                value: year['value'] as int,
                child: Text(year['label'] as String),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedYearLevel = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedSemester,
            decoration: InputDecoration(
              labelText: 'Semester',
              prefixIcon: const Icon(Icons.calendar_today),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _semesters.map((semester) {
              return DropdownMenuItem<int>(
                value: semester['value'] as int,
                child: Text(semester['label'] as String),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedSemester = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchStudyLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Study Load'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              title: 'Subjects',
              value: _subjects.length.toString(),
              color: Colors.blue,
              icon: Icons.menu_book,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryItem(
              title: 'Total Units',
              value: _grandTotalUnits.toStringAsFixed(2),
              color: Colors.green,
              icon: Icons.calculate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildApiSubjectCard(Map<String, dynamic> subject) {
    final subjectCode = subject['subjectCode']?.toString() ?? '-';
    final subjectTitle = subject['subjectTitle']?.toString() ?? '-';
    final lecUnits = _toDouble(subject['lecUnits']);
    final labUnits = _toDouble(subject['labUnits']);
    final totalUnits = _toDouble(subject['totalUnits']);

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
                  '${totalUnits.toStringAsFixed(2)} units',
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
                'Lecture Units: ${lecUnits.toStringAsFixed(2)}',
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
                'Laboratory Units: ${labUnits.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInView(AuthProvider authProvider) {
    return RefreshIndicator(
      onRefresh: _fetchStudyLoad,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStudentCard(authProvider),
          const SizedBox(height: 20),
          _buildFilterCard(),
          const SizedBox(height: 20),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          const Text(
            'Subjects',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_subjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, size: 42, color: Colors.orange),
                  SizedBox(height: 12),
                  Text(
                    'No study load available yet.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your study load has not been posted yet for the selected program, year level, and semester.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            )
          else
            ..._subjects.map(_buildApiSubjectCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isSignedIn = authProvider.isAuthenticated;

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
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: !isSignedIn
              ? _buildNotSignedInView()
              : _buildSignedInView(authProvider),
        ),
      ),
    );
  }
}
