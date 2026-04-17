import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enrollment_request.dart';
import '../../models/shared.dart';
import '../../providers/enrollment_management_provider.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Document Verification'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<EnrollmentManagementProvider>(
        builder: (context, provider, child) {
          final pendingEnrollments = provider.getEnrollmentsByStatus(EnrollmentStatus.pending);
          
          if (pendingEnrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No documents to verify',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingEnrollments.length,
            itemBuilder: (context, index) {
              return _buildDocumentCard(pendingEnrollments[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(EnrollmentRequest enrollment) {
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
              color: Colors.teal[50],
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
                    Icon(Icons.description, color: Colors.teal[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enrollment.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(enrollment.studentType.toString().split('.')[1]),
                      backgroundColor: Colors.teal[100],
                      labelStyle: TextStyle(color: Colors.teal[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Program: ${enrollment.program}',
                  style: TextStyle(color: Colors.teal[600]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uploaded Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDocumentItem('Transcript of Records', 'PDF', '2.3 MB', true),
                _buildDocumentItem('Birth Certificate', 'PDF', '1.1 MB', true),
                _buildDocumentItem('Certificate of Good Moral', 'PDF', '856 KB', false),
                _buildDocumentItem('2x2 ID Picture', 'JPG', '245 KB', true),
                if (enrollment.studentType == StudentType.newIncoming)
                  _buildDocumentItem('Parent\'s Consent', 'PDF', '1.5 MB', false),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showVerifyDialog(enrollment),
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify Documents'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(enrollment),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
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

  Widget _buildDocumentItem(String documentName, String type, String size, bool isVerified) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isVerified ? Colors.green[50] : Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.visibility,
            color: isVerified ? Colors.green : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isVerified ? Colors.green[700] : Colors.black87,
                  ),
                ),
                Text(
                  '$type  $size',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Verified',
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
                    content: Text('Opening document viewer...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('View'),
            ),
        ],
      ),
    );
  }

  void _showVerifyDialog(EnrollmentRequest enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Documents'),
        content: Text('Are you sure all documents for ${enrollment.studentName} are authentic and complete?'),
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
                  content: Text('Documents verified successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(EnrollmentRequest enrollment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please specify the reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
                hintText: 'e.g., Document appears to be tampered',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rejection notice sent to ${enrollment.studentName}.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
