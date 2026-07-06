import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/constants/api_constants.dart';
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
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_edit_screen.dart';

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
  bool _isRejecting = false;
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

      // Try to load applicant's profile photo
      pw.ImageProvider? profileImage;
      try {
        final profileFileName = app.applicantProfile;
        if (profileFileName != null && profileFileName.isNotEmpty) {
          String profileUrl = profileFileName;
          if (!profileUrl.startsWith('http')) {
            profileUrl = '${ApiConstants.baseUrl.replaceAll('/api/1', '')}/bgp_uploads/profile/$profileFileName';
          }
          final response = await http.get(Uri.parse(profileUrl));
          if (response.statusCode == 200) {
            profileImage = pw.MemoryImage(response.bodyBytes);
          }
        }
      } catch (_) {
        // Silently fail — will show placeholder text
      }

      final maroon = PdfColor.fromHex('#4A1C1C');
      final borderColor = PdfColors.grey400;
      final labelBg = PdfColor.fromHex('#F9F9F9');
      final cellBorder = pw.BorderSide(color: borderColor, width: 0.5);
      final tableBorder = pw.TableBorder.all(color: borderColor, width: 0.5);

      String fmtDate(String? d) {
        if (d == null) return '--';
        try {
          return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
        } catch (_) {
          return d;
        }
      }

      String fmtCurrency(double? v) {
        if (v == null) return '';
        final formatted = v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{2})+(\d)(?!\d))'),
          (m) => '${m[1]},',
        );
        return 'Rs. $formatted';
      }

      // Build a table row: label | value (matching admin panel HTML <td class="label"> | <td>)
      pw.TableRow buildTableRow(String label, String value) {
        return pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: labelBg,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ]);
      }

      // Section title badge (maroon background, white text)
      pw.Widget sectionTitle(String title) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: pw.BoxDecoration(
            color: maroon,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(title,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        );
      }

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BURHANI GUARDS PUNE',
                          style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: maroon)),
                      pw.SizedBox(height: 3),
                      pw.Text('Qardan Hasana Application Form',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(app.applicationNo,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: maroon)),
                      pw.Text('Date: ${fmtDate(app.createdAt)}',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 2, color: maroon),
              pw.SizedBox(height: 12),

              // ── APPLICANT DETAILS (with photo) ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        sectionTitle('Applicant Details'),
                        pw.Table(
                          border: tableBorder,
                          columnWidths: {
                            0: const pw.FlexColumnWidth(35),
                            1: const pw.FlexColumnWidth(65),
                          },
                          children: [
                            buildTableRow('Name (As Per BGP)', app.applicantMemberName ?? app.applicantName),
                            buildTableRow('Name (As Per Bank)', app.applicantName),
                            buildTableRow('ITS No.', app.applicantItsId),
                            buildTableRow('Mohallah', app.applicantJamaat),
                            buildTableRow('Occupation', app.applicantOccupation ?? '\u2014'),
                            buildTableRow('Mobile', app.applicantMobile),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 18),
                  pw.Container(
                    width: 90,
                    height: 108,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: profileImage != null
                        ? pw.ClipRRect(
                            horizontalRadius: 4,
                            verticalRadius: 4,
                            child: pw.Image(profileImage, fit: pw.BoxFit.cover))
                        : pw.Center(
                            child: pw.Text("Applicant's\nPhoto",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── QARDAN HASANA DETAILS ──
              sectionTitle('Qardan Hasana Details'),
              pw.Table(
                border: tableBorder,
                columnWidths: {
                  0: const pw.FlexColumnWidth(35),
                  1: const pw.FlexColumnWidth(65),
                },
                children: [
                  buildTableRow('Amount Requested', fmtCurrency(app.amountRequested)),
                  buildTableRow('Reason', app.reason ?? '\u2014'),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── GUARANTORS (side by side) ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        sectionTitle('Guarantor 1'),
                        pw.Table(
                          border: tableBorder,
                          columnWidths: {
                            0: const pw.FlexColumnWidth(40),
                            1: const pw.FlexColumnWidth(60),
                          },
                          children: [
                            buildTableRow('Name', app.captainName),
                            buildTableRow('Mobile No', app.captainMobile ?? '\u2014'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        sectionTitle('Guarantor 2'),
                        pw.Table(
                          border: tableBorder,
                          columnWidths: {
                            0: const pw.FlexColumnWidth(40),
                            1: const pw.FlexColumnWidth(60),
                          },
                          children: [
                            buildTableRow('Name', app.guarantorName),
                            buildTableRow('Mobile No', app.guarantorMobile ?? '\u2014'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── OFFICE USE ONLY ──
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FOR OFFICE USE ONLY',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: maroon)),
                    pw.SizedBox(height: 8),
                    pw.Table(
                      border: tableBorder,
                      columnWidths: {
                        0: const pw.FlexColumnWidth(40),
                        1: const pw.FlexColumnWidth(60),
                      },
                      children: [
                        buildTableRow('Sanctioned Amount', app.sanctionedAmount != null ? fmtCurrency(app.sanctionedAmount) : ''),
                        buildTableRow('Installment Amount', app.installmentAmount != null ? fmtCurrency(app.installmentAmount) : ''),
                        buildTableRow('No. of Months', app.numberOfMonths?.toString() ?? ''),
                        buildTableRow('Installment Date From', app.installmentDateFrom != null ? fmtDate(app.installmentDateFrom) : ''),
                        buildTableRow('Installment Date To', app.installmentDateTo != null ? fmtDate(app.installmentDateTo) : ''),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ── TERMS & CONDITIONS ──
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Terms & Conditions',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: maroon)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '1. Nature of Qardan: The amount given under this scheme is Qardan Hasana (interest-free), with maximum limit Rs. 20,000.\n'
                      '2. Eligibility: Only registered BGP members are eligible to apply.\n'
                      '3. Guarantors: Two guarantors required from the same Mohallah as the applicant.\n'
                      '4. Repayment: Without delay as per agreed schedule. Early repayment encouraged.\n'
                      '5. Default: In case of default, guarantors will be held responsible.\n'
                      '6. Declaration: I declare all information is true and correct.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Future<void> _guarantorApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Approval'),
        content: const Text(
          'Are you sure you want to approve this Qardan Hasana application as Guarantor?\n\n'
          'By approving, you accept joint responsibility for repayment in case of default.',
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
      await _service.guarantorApprove(widget.applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application approved successfully!'),
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

  Future<void> _guarantorReject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to reject this application?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRejecting = true);
    try {
      await _service.guarantorReject(widget.applicationId,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application rejected.'),
            backgroundColor: AppColors.error,
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
      if (mounted) setState(() => _isRejecting = false);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      if (app.status == 'sanctioned' && app.sanctionedAmount != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sanctioned Amount',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${app.sanctionedAmount!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Requested Amount',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${app.amountRequested.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Requested Amount',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${app.amountRequested.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── PROGRESS BAR ──
          Container(
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
                const Text('Application Progress',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Submitted (always complete)
                    _buildProgressStep(
                      icon: Icons.check_circle,
                      label: 'Submitted',
                      date: _formatShortDate(app.createdAt),
                      isComplete: true,
                      isActive: false,
                      isRejected: false,
                    ),
                    // Connector 1
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          color: app.captainApproved
                              ? AppColors.success
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Step 2: Guarantor 1 Approval
                    _buildProgressStep(
                      icon: app.captainApproved
                          ? Icons.check_circle
                          : Icons.schedule,
                      label: app.captainApproved
                          ? 'G1\nApproved'
                          : 'Awaiting\nG1',
                      date: app.captainApprovedAt != null
                          ? _formatShortDate(app.captainApprovedAt)
                          : 'Pending',
                      isComplete: app.captainApproved,
                      isActive: !app.captainApproved && app.status != 'rejected',
                      isRejected: false,
                    ),
                    // Connector 2
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          color: app.guarantorApproved
                              ? AppColors.success
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Step 3: Guarantor 2 Approval
                    _buildProgressStep(
                      icon: app.guarantorApproved
                          ? Icons.check_circle
                          : Icons.schedule,
                      label: app.guarantorApproved
                          ? 'G2\nApproved'
                          : 'Awaiting\nG2',
                      date: app.guarantorApprovedAt != null
                          ? _formatShortDate(app.guarantorApprovedAt)
                          : 'Pending',
                      isComplete: app.guarantorApproved,
                      isActive: !app.guarantorApproved && app.captainApproved && app.status != 'rejected',
                      isRejected: false,
                    ),
                    // Connector 3
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          color: app.status == 'sanctioned'
                              ? AppColors.success
                              : app.status == 'rejected'
                                  ? AppColors.error
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Step 4: Admin Decision
                    _buildProgressStep(
                      icon: app.status == 'sanctioned'
                          ? Icons.check_circle
                          : app.status == 'rejected'
                              ? Icons.cancel
                              : Icons.schedule,
                      label: app.status == 'sanctioned'
                          ? 'Sanctioned'
                          : app.status == 'rejected'
                              ? 'Rejected'
                              : 'Admin\nDecision',
                      date: app.adminApprovedAt != null
                          ? _formatShortDate(app.adminApprovedAt)
                          : 'Pending',
                      isComplete: app.status == 'sanctioned',
                      isActive: app.status == 'pending' && app.captainApproved && app.guarantorApproved,
                      isRejected: app.status == 'rejected',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── APPLICANT INFORMATION ──
          _buildSectionCard(
            'Applicant Information',
            Icons.person_outline,
            [
              _buildDetailRow('Application No', app.applicationNo),
              _buildDetailRow('Date', _formatShortDate(app.createdAt)),
              _buildDetailRow('Mohallah', app.applicantJamaat),
              _buildDetailRow('ITS No', app.applicantItsId),
              _buildDetailRow('Name (As per Member DB)', app.applicantMemberName ?? '—'),
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
              // Guarantor 1
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
                          child: const Text('Guarantor 1',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        // Guarantor 1 Approval Badge
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildVerticalDetail('Name', app.captainName),
                              _buildVerticalDetail('ITS ID', app.captainItsId ?? '—'),
                              _buildVerticalDetail('Mobile', app.captainMobile ?? '—'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildGuarantorImage(app.captainProfile),
                      ],
                    ),
                    // Approve/Reject buttons for Guarantor 1
                    if (!app.captainApproved &&
                        app.captainMemberId == _currentUserId &&
                        app.status == 'pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isApproving ? null : _guarantorApprove,
                              icon: _isApproving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(
                                  _isApproving ? 'Approving...' : 'Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isRejecting ? null : _guarantorReject,
                              icon: _isRejecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.error))
                                  : const Icon(Icons.cancel_outlined, size: 18),
                              label: Text(
                                  _isRejecting ? 'Rejecting...' : 'Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Guarantor 2
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.08),
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
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Guarantor 2',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        // Guarantor 2 Approval Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: app.guarantorApproved
                                ? AppColors.success.withOpacity(0.12)
                                : AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: app.guarantorApproved
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                app.guarantorApproved
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 14,
                                color: app.guarantorApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                app.guarantorApproved ? 'Approved' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: app.guarantorApproved
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildVerticalDetail('Name', app.guarantorName),
                              _buildVerticalDetail('ITS ID', app.guarantorItsId ?? '—'),
                              _buildVerticalDetail('Mobile', app.guarantorMobile ?? '—'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildGuarantorImage(app.guarantorProfile),
                      ],
                    ),
                    // Approve/Reject buttons for Guarantor 2
                    if (!app.guarantorApproved &&
                        app.guarantorMemberId == _currentUserId &&
                        app.status == 'pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isApproving ? null : _guarantorApprove,
                              icon: _isApproving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(
                                  _isApproving ? 'Approving...' : 'Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isRejecting ? null : _guarantorReject,
                              icon: _isRejecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.error))
                                  : const Icon(Icons.cancel_outlined, size: 18),
                              label: Text(
                                  _isRejecting ? 'Rejecting...' : 'Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
            const SizedBox(height: 12),
            // Download PDF Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadPdf,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  _isDownloading ? 'Generating PDF...' : 'Download Form PDF',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A1C1C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
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

          // ── EDIT BUTTON (for applicant, before any guarantor approval) ──
          if (app.status == 'pending' && app.applicantMemberId == _currentUserId) ...[
            if (!app.captainApproved && !app.guarantorApproved) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QardanEditScreen(application: app),
                      ),
                    );
                    if (result == true) {
                      _loadApplication(); // Refresh data after edit
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Edit Application',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: null, // Disabled
                        icon: const Icon(Icons.edit_off_rounded, size: 20),
                        label: const Text('Edit Application',
                            style:
                                TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Application is already approved by the guarantor',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGuarantorImage(String? profilePath) {
    String? imageUrl;
    if (profilePath != null && profilePath.isNotEmpty) {
      if (profilePath.startsWith('http://') ||
          profilePath.startsWith('https://')) {
        imageUrl = profilePath;
      } else {
        String cleanPath =
            profilePath.startsWith('/') ? profilePath.substring(1) : profilePath;
        if (!cleanPath.startsWith('bgp_uploads/')) {
          cleanPath = 'bgp_uploads/profile/$cleanPath';
        }
        imageUrl = '${ApiConstants.baseUrl}/$cleanPath';
      }
    }

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
        color: Colors.white,
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 72,
                height: 72,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: AppColors.textHint,
                  size: 36,
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              )
            : const Icon(
                Icons.person,
                color: AppColors.textHint,
                size: 36,
              ),
      ),
    );
  }

  Widget _buildVerticalDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
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

  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required String date,
    required bool isComplete,
    required bool isActive,
    required bool isRejected,
  }) {
    Color circleColor;
    Color iconColor;
    Color textColor;

    if (isRejected) {
      circleColor = AppColors.error.withOpacity(0.12);
      iconColor = AppColors.error;
      textColor = AppColors.error;
    } else if (isComplete) {
      circleColor = AppColors.success.withOpacity(0.12);
      iconColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isActive) {
      circleColor = AppColors.warning.withOpacity(0.12);
      iconColor = AppColors.warning;
      textColor = AppColors.warning;
    } else {
      circleColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade400;
      textColor = Colors.grey.shade400;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isRejected
                  ? AppColors.error.withOpacity(0.3)
                  : isComplete
                      ? AppColors.success.withOpacity(0.3)
                      : isActive
                          ? AppColors.warning.withOpacity(0.3)
                          : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2)),
        const SizedBox(height: 2),
        Text(date,
            style: TextStyle(
                fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }
}
