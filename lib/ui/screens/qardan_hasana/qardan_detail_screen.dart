import 'dart:io';
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/models/qardan_hasana_model.dart';
import 'package:burhaniguardsapp/core/services/qardan_hasana_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class QardanDetailScreen extends StatefulWidget {
  final int applicationId;

  const QardanDetailScreen({Key? key, required this.applicationId})
      : super(key: key);

  @override
  State<QardanDetailScreen> createState() => _QardanDetailScreenState();
}

class _QardanDetailScreenState extends State<QardanDetailScreen> {
  final QardanHasanaService _service = QardanHasanaService();
  final LocalStorageService _localStorage = LocalStorageService();
  QardanHasanaApplication? _application;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isApproving = false;
  bool _isCaptain = false;
  int _currentUserId = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadApplication();
  }

  Future<void> _loadUserRole() async {
    final userData = await _localStorage.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _isCaptain = userData.roles == 2;
        _currentUserId = userData.id;
      });
    }
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
    if (_application == null) return;
    setState(() => _isDownloading = true);
    try {
      final app = _application!;
      final pdfDoc = pw.Document();

      final labelStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
      final valueStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

      String fmtDate(String? d) {
        if (d == null) return '--';
        try {
          return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
        } catch (_) {
          return d;
        }
      }

      pw.Widget buildRow(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(label, style: labelStyle),
              ),
              pw.Text(': ', style: labelStyle),
              pw.Expanded(
                child: pw.Text(value, style: valueStyle),
              ),
            ],
          ),
        );
      }

      pw.Widget buildSection(String title, List<pw.Widget> children) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#4A1C1C'),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ),
              pw.SizedBox(height: 6),
              ...children,
            ],
          ),
        );
      }

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BURHANI GUARDS PUNE',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#4A1C1C'))),
                      pw.Text('Qardan Hasana Application Form',
                          style: pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(app.applicationNo,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#4A1C1C'))),
                      pw.Text('Date: ${fmtDate(app.createdAt)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#4A1C1C')),
              pw.SizedBox(height: 10),
            ],
          ),
          // footer: (context) => pw.Container(
          //   alignment: pw.Alignment.center,
          //   margin: const pw.EdgeInsets.only(top: 10),
          //   child: pw.Text(
          //     'Generated by Burhani Guards Pune - Qardan Hasana Module',
          //     style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          //   ),
          // ),
          build: (context) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: buildSection('Applicant Details', [
                    buildRow('Name (As Per Bank)', app.applicantName),
                    buildRow('ITS No.', app.applicantItsId),
                    buildRow('Mohallah', app.applicantJamaat),
                    buildRow('Occupation', app.applicantOccupation ?? '--'),
                    buildRow('Mobile', app.applicantMobile),
                  ]),
                ),
                pw.SizedBox(width: 20),
                pw.Container(
                  width: 90,
                  height: 110,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700),
                  ),
                  child: pw.Center(
                    child: pw.Text("Applicant's\nPhoto", 
                      textAlign: pw.TextAlign.center, 
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
                  ),
                ),
              ],
            ),

            // Loan Details
            buildSection('Qardan Hasana Details', [
              buildRow('Amount Requested', 'Rs. ${app.amountRequested.toStringAsFixed(2)}'),
              buildRow('Reason', app.reason ?? '--'),
              if (app.sanctionedAmount != null)
                buildRow('Sanctioned Amount', 'Rs. ${app.sanctionedAmount!.toStringAsFixed(2)}'),
            ]),

            // Guarantor 1: Captain
            buildSection('Guarantor 1 - Captain', [
              buildRow('Name', app.captainName),
              buildRow('Mobile', app.captainMobile ?? '--'),
            ]),

            // Guarantor 2: Member
            buildSection('Guarantor 2 - Member', [
              buildRow('Name', app.guarantorName),
              buildRow('Mobile', app.guarantorMobile ?? '--'),
            ]),

            // Terms
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Terms & Conditions',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#4A1C1C'))),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '1. Nature of Qardan: The amount given under this scheme is Qardan Hasana (interest-free), with maximum limit Rs. 20,000.\n'
                    '2. Eligibility: Only registered BGP members are eligible to apply.\n'
                    '3. Application: Applicant must provide personal details, reason, and two guarantors.\n'
                    '4. Guarantors: Two guarantors required - Captain (Guarantor 1) and a BGP member (Guarantor 2).\n'
                    '5. Default: In case of default, guarantors will be held responsible.\n'
                    '6. Declaration: I declare all information is true and correct.',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 8),
                  // pw.Text(
                  //   'Terms Accepted: ${app.termsAccepted ? "YES" : "NO"}',
                  //   style: pw.TextStyle(
                  //       fontSize: 9, fontWeight: pw.FontWeight.bold),
                  // ),
                ],
              ),
            ),

            // Office Use Only
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Office Use Only',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#4A1C1C'))),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Text('Sanctioned Amount: Rs. ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                    ]
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Text('Installment Amount: Rs. ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                      pw.SizedBox(width: 10),
                      pw.Text('X', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 10),
                      pw.Container(width: 60, height: 1, color: PdfColors.black),
                      pw.SizedBox(width: 5),
                      pw.Text('Months', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Text('Installment Date: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                      pw.SizedBox(width: 10),
                      pw.Text('To: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                    ]
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Text('Signature: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                    ]
                  ),
                ],
              ),
            ),

            // Signature spaces
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, child: pw.Divider()),
                    pw.Text('Applicant Signature',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, child: pw.Divider()),
                    pw.Text('Captain Signature',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, child: pw.Divider()),
                    pw.Text('Guarantor Signature',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdfDoc.save();
      final fileName = 'Qardan_Hasana_${app.applicationNo}.pdf';

      // Save to app documents directory (always works)
      final appDir = await getApplicationDocumentsDirectory();
      final appFile = File('${appDir.path}/$fileName');
      await appFile.writeAsBytes(pdfBytes);

      // Also save to public Downloads folder so it's visible in file manager
      File downloadFile = appFile; // fallback
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          downloadFile = File('${downloadsDir.path}/$fileName');
          await downloadFile.writeAsBytes(pdfBytes);
        }
      } catch (_) {
        // If saving to Downloads fails, we still have the app directory copy
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                const SizedBox(width: 10),
                const Expanded(child: Text('PDF Downloaded', style: TextStyle(fontSize: 17))),
              ],
            ),
            content: Text(
              'Saved to Downloads folder:\n$fileName',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  OpenFilex.open(downloadFile.path);
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles([XFile(downloadFile.path)],
                      text: 'Qardan Hasana Application Form');
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
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

  Future<void> _captainApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Approval'),
        content: const Text(
          'Are you sure you want to approve this Qardan Hasana application as Captain?\n\n'
          // 'By approving, you confirm that the applicant has collected your physical signature on the form.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isApproving = true);
    try {
      await _service.captainApprove(widget.applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application approved successfully! Admins have been notified.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadApplication(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
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
                    Row(
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
                        const Spacer(),
                        // Captain Approval Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: app.captainApproved
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: app.captainApproved
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                app.captainApproved
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 14,
                                color: app.captainApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                app.captainApproved ? 'Approved' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: app.captainApproved
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Name', app.captainName),
                    _buildDetailRow('Mobile', app.captainMobile ?? '—'),
                    // Captain Approve Button
                    if (_isCaptain &&
                        !app.captainApproved &&
                        app.captainMemberId == _currentUserId) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isApproving ? null : _captainApprove,
                          icon: _isApproving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                              _isApproving ? 'Approving...' : 'Approve as Captain'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
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
