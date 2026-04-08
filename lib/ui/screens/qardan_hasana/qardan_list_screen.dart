import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/models/qardan_hasana_model.dart';
import 'package:burhaniguardsapp/core/services/qardan_hasana_service.dart';
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_apply_screen.dart';
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_detail_screen.dart';
import 'package:burhaniguardsapp/ui/screens/user/memberDashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QardanListScreen extends StatefulWidget {
  const QardanListScreen({Key? key}) : super(key: key);

  @override
  State<QardanListScreen> createState() => _QardanListScreenState();
}

class _QardanListScreenState extends State<QardanListScreen> {
  final QardanHasanaService _service = QardanHasanaService();
  List<QardanHasanaListItem> _applications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _applications = await _service.getMyApplications();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
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
        return 'Submitted';
      case 'sanctioned':
        return 'Sanctioned';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    void _goHome() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeMiqaatScreen()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
        ),
        title: const Text('My Qardan Applications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
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
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApplications,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64,
                              color: AppColors.primary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text(
                            'No applications yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Apply for Qardan Hasana using the button below',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          return _buildApplicationCard(app);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QardanApplyScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Apply',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
    );
  }

  Widget _buildApplicationCard(QardanHasanaListItem app) {
    final statusColor = _getStatusColor(app.status);
    final statusLabel = _getStatusLabel(app.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => QardanDetailScreen(applicationId: app.id)),
          );
          _loadApplications();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Application No + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    app.applicationNo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Amount
              Row(
                children: [
                  const Icon(Icons.currency_rupee,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '₹${app.amountRequested.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (app.sanctionedAmount != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(Sanctioned: ₹${app.sanctionedAmount!.toStringAsFixed(0)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(app.createdAt),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      app.applicantJamaat,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
