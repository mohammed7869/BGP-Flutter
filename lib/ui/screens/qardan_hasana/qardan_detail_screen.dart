import 'dart:io';
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/models/qardan_hasana_model.dart';
import 'package:burhaniguardsapp/core/services/qardan_hasana_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QardanDetailScreen extends StatefulWidget {
  final int applicationId;

  const QardanDetailScreen({Key? key, required this.applicationId})
      : super(key: key);

  @override
  State<QardanDetailScreen> createState() => _QardanDetailScreenState();
}

class _QardanDetailScreenState extends State<QardanDetailScreen> {
  final QardanHasanaService _service = QardanHasanaService();
  QardanHasanaApplication? _application;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _application = await _service.getApplicationById(widget.applicationId);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _service.downloadPdf(widget.applicationId);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/Qardan_Hasana_${_application?.applicationNo ?? widget.applicationId}.html');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Form downloaded successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () {
                Share.shareXFiles([XFile(file.path)],
                    text: 'Qardan Hasana Application Form');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'submitted_to_admin':
        return AppColors.info;
      case 'sanctioned':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'submitted_to_admin':
        return 'Submitted to Admin';
      case 'sanctioned':
        return 'Sanctioned';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_bottom;
      case 'submitted_to_admin':
        return Icons.upload_file;
      case 'sanctioned':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatShortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          _application?.applicationNo ?? 'Application Details',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          if (_application != null)
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              onPressed: _isDownloading ? null : _downloadPdf,
              tooltip: 'Download Form',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: AppColors.error.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApplication,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final app = _application!;
    final statusColor = _getStatusColor(app.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── STATUS BANNER ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getStatusIcon(app.status),
                      color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusLabel(app.status),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied on ${_formatShortDate(app.createdAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${app.amountRequested.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text('Requested',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── APPLICANT INFORMATION ──
          _buildSectionCard(
            'Applicant Information',
            Icons.person_outline,
            [
              _buildDetailRow('Application No', app.applicationNo),
              _buildDetailRow('Date', _formatShortDate(app.createdAt)),
              _buildDetailRow('Mohallah', app.applicantJamaat),
              _buildDetailRow('ITS No', app.applicantItsId),
              _buildDetailRow('Name (As Per Bank)', app.applicantName),
              _buildDetailRow('Occupation', app.applicantOccupation ?? '—'),
              _buildDetailRow('Mobile No', app.applicantMobile),
              _buildDetailRow('Reason', app.reason ?? '—'),
              _buildDetailRow(
                  'Amount', '₹${app.amountRequested.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 16),

          // ── GUARANTOR SECTION ──
          _buildSectionCard(
            'Guarantor Section',
            Icons.verified_user_outlined,
            [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Guarantor 1 — Captain',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Name', app.captainName),
                    _buildDetailRow('Mobile', app.captainMobile ?? '—'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Guarantor 2 — Member',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Name', app.guarantorName),
                    _buildDetailRow('Mobile', app.guarantorMobile ?? '—'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── OFFICE USE ONLY (if sanctioned) ──
          if (app.status == 'sanctioned' && app.sanctionedAmount != null) ...[
            _buildSectionCard(
              'Office Use Only',
              Icons.admin_panel_settings_outlined,
              [
                _buildDetailRow('Sanctioned Amount',
                    '₹${app.sanctionedAmount!.toStringAsFixed(2)}'),
                if (app.installmentAmount != null)
                  _buildDetailRow('Installment Amount',
                      '₹${app.installmentAmount!.toStringAsFixed(2)}'),
                if (app.numberOfMonths != null)
                  _buildDetailRow(
                      'No. of Months', app.numberOfMonths.toString()),
                if (app.installmentDateFrom != null)
                  _buildDetailRow('Installment From',
                      _formatShortDate(app.installmentDateFrom)),
                if (app.installmentDateTo != null)
                  _buildDetailRow('Installment To',
                      _formatShortDate(app.installmentDateTo)),
                if (app.adminApprovedAt != null)
                  _buildDetailRow(
                      'Approved On', _formatDate(app.adminApprovedAt)),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── REJECTION REASON ──
          if (app.status == 'rejected' && app.rejectionReason != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Rejection Reason',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(app.rejectionReason!,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── DOWNLOAD BUTTON ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isDownloading ? null : _downloadPdf,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.download_rounded),
              label: Text(_isDownloading ? 'Downloading...' : 'Download Form'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
