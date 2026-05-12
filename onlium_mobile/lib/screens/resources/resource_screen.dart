import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  static const String _baseUrl = 'https://localhost:7164';

  bool _isLoading = true;
  bool _isForbidden = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _resources = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _isForbidden = false;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _resources = [];
          _errorMessage = 'You are not logged in. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/Resources'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          _resources = List<Map<String, dynamic>>.from(decoded);
          _isForbidden = false;
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 403) {
        final message = _extractMessage(
          response.body,
          fallback:
              'LMS resources are currently available only to BSIT and BSCS students. This resource is not available for your enrolled course.',
        );

        setState(() {
          _resources = [];
          _isForbidden = true;
          _errorMessage = message;
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 401) {
        setState(() {
          _resources = [];
          _errorMessage = 'Your session has expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final message = _extractMessage(
        response.body,
        fallback: 'Failed to load resources. Status: ${response.statusCode}.',
      );

      setState(() {
        _resources = [];
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _resources = [];
        _errorMessage = 'Unable to connect to the server. Details: $e';
        _isLoading = false;
      });
    }
  }

  String _extractMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? fallback;
      }

      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Map<String, dynamic>? get _examResource {
    final matches = _resources.where((resource) {
      final type = resource['resourceType']?.toString().toLowerCase().trim();
      return type == 'exam' || type == 'lms exam';
    }).toList();

    if (matches.isEmpty) return null;
    return matches.first;
  }

  Map<String, dynamic>? get _quizResource {
    final matches = _resources.where((resource) {
      final type = resource['resourceType']?.toString().toLowerCase().trim();
      return type == 'quiz' || type == 'lms quiz';
    }).toList();

    if (matches.isEmpty) return null;
    return matches.first;
  }

  bool get _hasAnyResource => _examResource != null || _quizResource != null;

  Color _resourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
      case 'lms exam':
        return const Color(0xFF1E63B6);
      case 'quiz':
      case 'lms quiz':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _resourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
      case 'lms exam':
        return Icons.assignment_rounded;
      case 'quiz':
      case 'lms quiz':
        return Icons.quiz_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  String _resourceDescription(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
      case 'lms exam':
        return 'Access your current online examination link.';
      case 'quiz':
      case 'lms quiz':
        return 'Access your current online quiz link.';
      default:
        return 'Open learning resource.';
    }
  }

  Future<void> _launchURL(String url) async {
    if (url.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url.trim());

    if (uri == null || !uri.hasAbsolutePath && uri.host.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid resource link.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            title: const Text('Resources'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: RefreshIndicator(
            onRefresh: _loadResources,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildLmsContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Management System',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Access your current LMS examination and quiz links posted by the administrator.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF627D98),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLmsContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isForbidden) {
      return _buildAccessNoticeCard();
    }

    if (_errorMessage != null) {
      return _buildErrorCard();
    }

    if (!_hasAnyResource) {
      return _buildNoResourcesCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResourceCard(
          sectionTitle: 'LMS Exam Link',
          resourceType: 'Exam',
          resource: _examResource,
        ),
        const SizedBox(height: 14),
        _buildResourceCard(
          sectionTitle: 'LMS Quiz Link',
          resourceType: 'Quiz',
          resource: _quizResource,
        ),
      ],
    );
  }

  Widget _buildAccessNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC857)),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 54, color: Color(0xFFB7791F)),
          const SizedBox(height: 14),
          const Text(
            'Resource Access Notice',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102A43),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ??
                'LMS resources are currently available only to BSIT and BSCS students. This resource is not available for your enrolled course.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF334E68),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 54, color: Colors.red[600]),
          const SizedBox(height: 14),
          const Text(
            'Unable to Load Resources',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadResources,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResourcesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 54, color: Colors.orange[700]),
          const SizedBox(height: 14),
          const Text(
            'No Resources Available Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please come back later. Your administrator has not posted any active exam or quiz resource yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard({
    required String sectionTitle,
    required String resourceType,
    required Map<String, dynamic>? resource,
  }) {
    final type = resource?['resourceType']?.toString() ?? resourceType;
    final title = resource?['title']?.toString() ?? '';
    final url = resource?['url']?.toString() ?? '';

    final color = _resourceColor(type);
    final icon = _resourceIcon(type);
    final description = _resourceDescription(type);

    if (resource == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EEF8)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'No active link is available yet.',
                    style: TextStyle(color: Color(0xFF627D98), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    color: Color(0xFF627D98),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF627D98),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  url,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: url.isEmpty ? null : () => _launchURL(url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
