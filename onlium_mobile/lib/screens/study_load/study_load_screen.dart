import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class StudyLoadScreen extends StatefulWidget {
  const StudyLoadScreen({super.key});

  @override
  State<StudyLoadScreen> createState() => _StudyLoadScreenState();
}

class _StudyLoadScreenState extends State<StudyLoadScreen> {
  final _formKey = GlobalKey<FormState>();

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

  String? _currentProgramCode;
  int? _currentYearLevel;
  int? _currentSemester;

  String _previewProgram = 'BSIT';
  int _previewYearLevel = 1;
  int _previewSemester = 1;

  bool _isLoadingMyStudyLoad = true;
  bool _isLoadingPreview = false;
  bool _isSaving = false;

  String? _myStudyLoadError;
  String? _previewError;

  List<Map<String, dynamic>> _mySubjects = [];
  List<Map<String, dynamic>> _previewSubjects = [];
  Map<String, dynamic>? _currentSubmission;

  final Map<String, TextEditingController> _sectionControllers = {};
  final Map<String, TextEditingController> _professorControllers = {};
  final Map<String, TextEditingController> _daysControllers = {};
  final Map<String, TextEditingController> _startTimeControllers = {};
  final Map<String, TextEditingController> _endTimeControllers = {};
  final Map<String, TextEditingController> _roomControllers = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyStudyLoad();
      _loadCurriculumPreview();
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in [
      ..._sectionControllers.values,
      ..._professorControllers.values,
      ..._daysControllers.values,
      ..._startTimeControllers.values,
      ..._endTimeControllers.values,
      ..._roomControllers.values,
    ]) {
      controller.dispose();
    }

    _sectionControllers.clear();
    _professorControllers.clear();
    _daysControllers.clear();
    _startTimeControllers.clear();
    _endTimeControllers.clear();
    _roomControllers.clear();
  }

  Map<String, String>? _authHeaders() {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.isEmpty) {
      return null;
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Map<String, String>? _jsonAuthHeaders() {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String get _currentStatus =>
      _currentSubmission?['status']?.toString() ?? 'Not Submitted';

  String get _normalizedStatus =>
      _currentStatus.trim().replaceAll(' ', '').toLowerCase();

  bool get _isLocked =>
      _normalizedStatus == 'pendingreview' || _normalizedStatus == 'approved';

  bool get _canEdit =>
      !_isLocked &&
      !_isSaving &&
      !_isLoadingMyStudyLoad &&
      _mySubjects.isNotEmpty;

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double get _myTotalUnits {
    return _mySubjects.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['totalUnits']),
    );
  }

  double get _previewTotalUnits {
    return _previewSubjects.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['totalUnits']),
    );
  }

  Future<void> _loadMyStudyLoad() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMyStudyLoad = true;
      _myStudyLoadError = null;
    });

    try {
      final headers = _authHeaders();

      if (headers == null) {
        if (!mounted) return;

        setState(() {
          _myStudyLoadError = 'Your session has expired. Please log in again.';
          _isLoadingMyStudyLoad = false;
        });
        return;
      }

      final currentTermResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/StudentStudyLoadSchedules/current-term',
        ),
        headers: headers,
      );

      if (currentTermResponse.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _mySubjects = [];
          _currentSubmission = null;
          _myStudyLoadError =
              _extractMessage(currentTermResponse.body) ??
              'Unable to load your current enrolled term. Status: ${currentTermResponse.statusCode}.';
          _isLoadingMyStudyLoad = false;
        });
        return;
      }

      final currentTerm = Map<String, dynamic>.from(
        jsonDecode(currentTermResponse.body) as Map,
      );

      final programCode = currentTerm['programCode']?.toString().toUpperCase();
      final yearLevel = _toInt(currentTerm['yearLevel']);
      final semester = _toInt(currentTerm['semester']);

      if (programCode == null || yearLevel == null || semester == null) {
        if (!mounted) return;

        setState(() {
          _myStudyLoadError =
              'Invalid current term data returned by the server.';
          _isLoadingMyStudyLoad = false;
        });
        return;
      }

      final officialUri =
          Uri.parse(
            '${ApiConfig.baseUrl}/api/StudentStudyLoadSchedules/official',
          ).replace(
            queryParameters: {
              'programCode': programCode,
              'yearLevel': yearLevel.toString(),
              'semester': semester.toString(),
            },
          );

      final officialResponse = await http.get(officialUri, headers: headers);

      if (officialResponse.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _mySubjects = [];
          _currentSubmission = null;
          _myStudyLoadError =
              _extractMessage(officialResponse.body) ??
              'Failed to load your official study load. Status: ${officialResponse.statusCode}.';
          _isLoadingMyStudyLoad = false;
        });
        return;
      }

      final mineResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/StudentStudyLoadSchedules/mine'),
        headers: headers,
      );

      if (mineResponse.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _mySubjects = [];
          _currentSubmission = null;
          _myStudyLoadError =
              _extractMessage(mineResponse.body) ??
              'Failed to load your submitted schedule. Status: ${mineResponse.statusCode}.';
          _isLoadingMyStudyLoad = false;
        });
        return;
      }

      final officialSubjects = _decodeList(officialResponse.body);
      final mySchedules = _decodeList(mineResponse.body);

      final matchingSubmission = _findCurrentSubmission(
        schedules: mySchedules,
        programCode: programCode,
        yearLevel: yearLevel,
        semester: semester,
      );

      _prepareControllers(
        subjects: officialSubjects,
        submission: matchingSubmission,
      );

      if (!mounted) return;

      setState(() {
        _currentProgramCode = programCode;
        _currentYearLevel = yearLevel;
        _currentSemester = semester;
        _mySubjects = officialSubjects;
        _currentSubmission = matchingSubmission;
        _myStudyLoadError = null;
        _isLoadingMyStudyLoad = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _myStudyLoadError = 'Error loading your study load: $e';
        _isLoadingMyStudyLoad = false;
      });
    }
  }

  Future<void> _loadCurriculumPreview() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });

    try {
      final headers = _authHeaders();

      if (headers == null) {
        if (!mounted) return;

        setState(() {
          _previewSubjects = [];
          _previewError = 'Your session has expired. Please log in again.';
          _isLoadingPreview = false;
        });
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/StudyLoads').replace(
        queryParameters: {
          'programCode': _previewProgram,
          'yearLevel': _previewYearLevel.toString(),
          'semester': _previewSemester.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _previewSubjects = _decodeList(response.body);
          _previewError = null;
          _isLoadingPreview = false;
        });
        return;
      }

      setState(() {
        _previewSubjects = [];
        _previewError =
            _extractMessage(response.body) ??
            'Failed to load curriculum preview. Status: ${response.statusCode}.';
        _isLoadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _previewSubjects = [];
        _previewError = 'Error loading curriculum preview: $e';
        _isLoadingPreview = false;
      });
    }
  }

  List<Map<String, dynamic>> _decodeList(String body) {
    final decoded = jsonDecode(body);

    if (decoded is! List) {
      return [];
    }

    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic>? _findCurrentSubmission({
    required List<Map<String, dynamic>> schedules,
    required String programCode,
    required int yearLevel,
    required int semester,
  }) {
    final matches = schedules.where((schedule) {
      final scheduleProgram = schedule['programCode']?.toString().toUpperCase();
      final scheduleYear = _toInt(schedule['yearLevel']);
      final scheduleSemester = _toInt(schedule['semester']);

      return scheduleProgram == programCode.toUpperCase() &&
          scheduleYear == yearLevel &&
          scheduleSemester == semester;
    }).toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final aDate =
          DateTime.tryParse(
            a['submittedAt']?.toString() ?? a['createdAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bDate =
          DateTime.tryParse(
            b['submittedAt']?.toString() ?? b['createdAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return matches.first;
  }

  void _prepareControllers({
    required List<Map<String, dynamic>> subjects,
    required Map<String, dynamic>? submission,
  }) {
    _disposeControllers();

    final submittedItems = <String, Map<String, dynamic>>{};
    final rawItems = submission?['items'];

    if (rawItems is List) {
      for (final item in rawItems) {
        final map = Map<String, dynamic>.from(item as Map);
        final studyLoadId = map['studyLoadId']?.toString();

        if (studyLoadId != null && studyLoadId.isNotEmpty) {
          submittedItems[studyLoadId] = map;
        }
      }
    }

    for (final subject in subjects) {
      final id = subject['id']?.toString() ?? '';
      final submitted = submittedItems[id];

      _sectionControllers[id] = TextEditingController(
        text: submitted?['section']?.toString() ?? '',
      );
      _professorControllers[id] = TextEditingController(
        text: submitted?['professorName']?.toString() ?? '',
      );
      _daysControllers[id] = TextEditingController(
        text: submitted?['days']?.toString() ?? '',
      );
      _startTimeControllers[id] = TextEditingController(
        text: submitted?['startTime']?.toString() ?? '',
      );
      _endTimeControllers[id] = TextEditingController(
        text: submitted?['endTime']?.toString() ?? '',
      );
      _roomControllers[id] = TextEditingController(
        text: submitted?['room']?.toString() ?? '',
      );
    }
  }

  TextEditingController _controllerOf(
    Map<String, TextEditingController> store,
    String id,
  ) {
    return store.putIfAbsent(id, () => TextEditingController());
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String _yearLabel(int? yearLevel) {
    switch (yearLevel) {
      case 1:
        return '1st Year';
      case 2:
        return '2nd Year';
      case 3:
        return '3rd Year';
      case 4:
        return '4th Year';
      default:
        return 'Year ${yearLevel ?? '-'}';
    }
  }

  String _semesterLabel(int? semester) {
    switch (semester) {
      case 1:
        return '1st Semester';
      case 2:
        return '2nd Semester';
      case 3:
        return 'Summer';
      default:
        return 'Semester ${semester ?? '-'}';
    }
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  String? _timeValidator(String? value, String fieldName) {
    final required = _requiredValidator(value, fieldName);
    if (required != null) return required;

    final time = value!.trim();
    final regex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

    if (!regex.hasMatch(time)) {
      return 'Use 24-hour format, e.g. 08:00 or 13:30.';
    }

    return null;
  }

  int? _parseTime(String value) {
    final parts = value.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return hour * 60 + minute;
  }

  bool _validateTimeOrder() {
    for (final subject in _mySubjects) {
      final id = subject['id']?.toString() ?? '';
      final code = subject['subjectCode']?.toString() ?? 'Subject';

      final start = _startTimeControllers[id]?.text.trim() ?? '';
      final end = _endTimeControllers[id]?.text.trim() ?? '';

      final startTime = _parseTime(start);
      final endTime = _parseTime(end);

      if (startTime == null || endTime == null) {
        continue;
      }

      if (endTime <= startTime) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$code: End time must be later than start time. Use 24-hour format, for example 11:00 to 13:30.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  TimeOfDay? _timeOfDayFromText(String value) {
    final parts = value.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initial = _timeOfDayFromText(controller.text) ?? TimeOfDay.now();

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null) return;

    controller.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _buildScheduleItemsPayload() {
    return _mySubjects.map((subject) {
      final id = subject['id']?.toString() ?? '';

      return {
        'studyLoadId': id,
        'section': _sectionControllers[id]?.text.trim() ?? '',
        'professorName': _professorControllers[id]?.text.trim() ?? '',
        'days': _daysControllers[id]?.text.trim() ?? '',
        'startTime': _startTimeControllers[id]?.text.trim() ?? '',
        'endTime': _endTimeControllers[id]?.text.trim() ?? '',
        'room': _roomControllers[id]?.text.trim(),
      };
    }).toList();
  }

  Future<void> _saveDraft() async {
    await _sendSchedule(endpoint: 'save-draft');
  }

  Future<void> _submitForValidation() async {
    await _sendSchedule(endpoint: 'submit');
  }

  Future<void> _sendSchedule({required String endpoint}) async {
    if (_currentProgramCode == null ||
        _currentYearLevel == null ||
        _currentSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current enrolled term is not loaded yet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mySubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subjects available to submit.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validateTimeOrder()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _myStudyLoadError = null;
    });

    try {
      final headers = _jsonAuthHeaders();

      if (headers == null) {
        if (!mounted) return;

        setState(() {
          _myStudyLoadError = 'Your session has expired. Please log in again.';
          _isSaving = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/StudentStudyLoadSchedules/$endpoint',
        ),
        headers: headers,
        body: jsonEncode({
          'programCode': _currentProgramCode,
          'yearLevel': _currentYearLevel,
          'semester': _currentSemester,
          'items': _buildScheduleItemsPayload(),
        }),
      );

      if (!mounted) return;

      final message = _extractMessage(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ??
                  (endpoint == 'submit'
                      ? 'Study load schedule submitted for validation.'
                      : 'Study load schedule draft saved.'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        await _loadMyStudyLoad();

        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        return;
      }

      setState(() {
        _myStudyLoadError =
            message ??
            'Failed to ${endpoint == 'submit' ? 'submit' : 'save'} schedule. Status: ${response.statusCode}.';
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_myStudyLoadError!),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _myStudyLoadError = 'Error saving schedule: $e';
        _isSaving = false;
      });
    }
  }

  String _displayStatus(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'pendingreview':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'notsubmitted':
        return 'Not Submitted';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().replaceAll(' ', '').toLowerCase()) {
      case 'draft':
        return Colors.blue;
      case 'pendingreview':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildNotSignedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
      decoration: _cardDecoration(),
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
        ],
      ),
    );
  }

  Widget _buildCurrentTermCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[700],
            child: const Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _currentProgramCode == null
                ? const Text(
                    'Current enrolled term is not available.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Enrolled Term',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_currentProgramCode • ${_yearLabel(_currentYearLevel)} • ${_semesterLabel(_currentSemester)}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF1E4A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _currentStatus;
    final color = _statusColor(status);
    final adminComment = _currentSubmission?['adminComment']?.toString();

    String message;

    switch (_normalizedStatus) {
      case 'draft':
        message =
            'Your schedule is saved as draft. Submit it for admin validation when ready.';
        break;
      case 'pendingreview':
        message = 'Your study load schedule is waiting for admin validation.';
        break;
      case 'approved':
        message = 'Your study load schedule has been validated by the admin.';
        break;
      case 'rejected':
        message =
            'Your study load schedule was rejected. Please check the comment, revise, and resubmit.';
        break;
      default:
        message =
            'Fill in your schedule details below and submit them for admin validation.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: const Icon(Icons.fact_check, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Schedule Status: ${_displayStatus(status)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (_normalizedStatus == 'rejected' &&
              adminComment != null &&
              adminComment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Admin Comment:',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              adminComment,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int subjects,
    required double totalUnits,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              title: 'Subjects',
              value: subjects.toString(),
              color: Colors.blue,
              icon: Icons.menu_book,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryItem(
              title: 'Total Units',
              value: totalUnits.toStringAsFixed(2),
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

  Widget _buildSubjectScheduleCard(Map<String, dynamic> subject) {
    final id = subject['id']?.toString() ?? '';
    final subjectCode = subject['subjectCode']?.toString() ?? '-';
    final subjectTitle = subject['subjectTitle']?.toString() ?? '-';
    final lecUnits = _toDouble(subject['lecUnits']);
    final labUnits = _toDouble(subject['labUnits']);
    final totalUnits = _toDouble(subject['totalUnits']);

    final sectionController = _controllerOf(_sectionControllers, id);
    final professorController = _controllerOf(_professorControllers, id);
    final daysController = _controllerOf(_daysControllers, id);
    final startController = _controllerOf(_startTimeControllers, id);
    final endController = _controllerOf(_endTimeControllers, id);
    final roomController = _controllerOf(_roomControllers, id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubjectHeader(
            subjectCode: subjectCode,
            subjectTitle: subjectTitle,
            totalUnits: totalUnits,
          ),
          const SizedBox(height: 12),
          Text(
            'Lecture Units: ${lecUnits.toStringAsFixed(2)} • Laboratory Units: ${labUnits.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: sectionController,
            enabled: _canEdit,
            decoration: const InputDecoration(
              labelText: 'Section',
              hintText: 'e.g. BSIT-22A',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.groups),
            ),
            validator: (value) => _requiredValidator(value, 'Section'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: professorController,
            enabled: _canEdit,
            decoration: const InputDecoration(
              labelText: 'Professor Name',
              hintText: 'e.g. Ms. Jovelyn Comaingking',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) => _requiredValidator(value, 'Professor name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: daysController,
            enabled: _canEdit,
            decoration: const InputDecoration(
              labelText: 'Days',
              hintText: 'e.g. Tue/Fri or MWF',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_month),
            ),
            validator: (value) => _requiredValidator(value, 'Days'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: startController,
                  enabled: _canEdit,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Time',
                    hintText: '08:00',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.access_time),
                    suffixIcon: IconButton(
                      onPressed: _canEdit
                          ? () => _pickTime(startController)
                          : null,
                      icon: const Icon(Icons.schedule),
                    ),
                  ),
                  validator: (value) => _timeValidator(value, 'Start time'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: endController,
                  enabled: _canEdit,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Time',
                    hintText: '13:30',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.access_time_filled),
                    suffixIcon: IconButton(
                      onPressed: _canEdit
                          ? () => _pickTime(endController)
                          : null,
                      icon: const Icon(Icons.schedule),
                    ),
                  ),
                  validator: (value) => _timeValidator(value, 'End time'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: roomController,
            enabled: _canEdit,
            decoration: const InputDecoration(
              labelText: 'Room',
              hintText: 'e.g. SLab 2',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.meeting_room),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHeader({
    required String subjectCode,
    required String subjectTitle,
    required double totalUnits,
  }) {
    return Row(
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
    );
  }

  Widget _buildActionButtons() {
    if (_mySubjects.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLocked) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: Text(
          _normalizedStatus == 'approved'
              ? 'This schedule has already been approved and cannot be edited.'
              : 'This schedule is pending admin review and cannot be edited for now.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _submitForValidation,
            icon: _isSaving
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
              _isSaving ? 'Saving...' : 'Submit for Admin Validation',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyStudyLoadTab(AuthProvider authProvider) {
    return RefreshIndicator(
      onRefresh: _loadMyStudyLoad,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStudentCard(authProvider),
            const SizedBox(height: 16),
            _buildCurrentTermCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(
              subjects: _mySubjects.length,
              totalUnits: _myTotalUnits,
            ),
            const SizedBox(height: 20),
            const Text(
              'Subjects and Schedule Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This area is limited to your current enrolled term. Fill in your section, professor, days, time, and room for each subject.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingMyStudyLoad)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_myStudyLoadError != null)
              _buildErrorBox(_myStudyLoadError!)
            else if (_mySubjects.isEmpty)
              _buildEmptyBox(
                title: 'No study load available yet.',
                message:
                    'Your official study load has not been posted yet for your current enrolled term.',
              )
            else ...[
              ..._mySubjects.map(_buildSubjectScheduleCard),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumPreviewTab() {
    return RefreshIndicator(
      onRefresh: _loadCurriculumPreview,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPreviewFilterCard(),
          const SizedBox(height: 16),
          _buildReadOnlyNotice(),
          const SizedBox(height: 16),
          _buildSummaryCard(
            subjects: _previewSubjects.length,
            totalUnits: _previewTotalUnits,
          ),
          const SizedBox(height: 20),
          const Text(
            'Curriculum Subjects',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingPreview)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_previewError != null)
            _buildErrorBox(_previewError!)
          else if (_previewSubjects.isEmpty)
            _buildEmptyBox(
              title: 'No subjects found.',
              message:
                  'No curriculum subjects were found for the selected program, year level, and semester.',
            )
          else
            ..._previewSubjects.map(_buildReadOnlySubjectCard),
        ],
      ),
    );
  }

  Widget _buildPreviewFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Curriculum Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You may browse other subjects here, but schedule submission is disabled in this tab.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _previewProgram,
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
            onChanged: _isLoadingPreview
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _previewProgram = value);
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _previewYearLevel,
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
            onChanged: _isLoadingPreview
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _previewYearLevel = value);
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _previewSemester,
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
            onChanged: _isLoadingPreview
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _previewSemester = value);
                  },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingPreview ? null : _loadCurriculumPreview,
              icon: const Icon(Icons.search),
              label: const Text('Load Preview'),
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

  Widget _buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Read-only preview. You can view subjects here, but you cannot submit schedules from this tab.',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlySubjectCard(Map<String, dynamic> subject) {
    final subjectCode = subject['subjectCode']?.toString() ?? '-';
    final subjectTitle = subject['subjectTitle']?.toString() ?? '-';
    final lecUnits = _toDouble(subject['lecUnits']);
    final labUnits = _toDouble(subject['labUnits']);
    final totalUnits = _toDouble(subject['totalUnits']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubjectHeader(
            subjectCode: subjectCode,
            subjectTitle: subjectTitle,
            totalUnits: totalUnits,
          ),
          const SizedBox(height: 12),
          Text(
            'Lecture Units: ${lecUnits.toStringAsFixed(2)} • Laboratory Units: ${labUnits.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildEmptyBox({required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 42, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orange),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isSignedIn = authProvider.isAuthenticated;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.fact_check), text: 'My Study Load'),
                  Tab(icon: Icon(Icons.visibility), text: 'Curriculum Preview'),
                ],
              ),
            ),
            body: !isSignedIn
                ? _buildNotSignedInView()
                : TabBarView(
                    children: [
                      _buildMyStudyLoadTab(authProvider),
                      _buildCurriculumPreviewTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
