import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/models/qardan_hasana_model.dart';
import 'package:burhaniguardsapp/core/services/qardan_hasana_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_apply_screen.dart';
import 'package:burhaniguardsapp/ui/screens/qardan_hasana/qardan_detail_screen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/common/bohraCalendarScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class QardanListScreen extends StatefulWidget {
  const QardanListScreen({Key? key}) : super(key: key);

  @override
  State<QardanListScreen> createState() => _QardanListScreenState();
}

class _QardanListScreenState extends State<QardanListScreen> {
  final QardanHasanaService _service = QardanHasanaService();
  final LocalStorageService _localStorage = LocalStorageService();
  List<QardanHasanaListItem> _applications = [];
  bool _isLoading = true;
  String? _error;
  bool _isCaptain = false;
  int _currentUserId = 0;
  bool _canApply = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndApplications();
  }

  Future<void> _loadUserAndApplications() async {
    final user = await _localStorage.getUserData();
    if (user != null) {
      setState(() {
        _isCaptain = user.roles == 2;
        _currentUserId = user.id;
      });
    }
    await _loadApplications();
    // Check eligibility
    final canApply = await _service.canApply();
    if (mounted) {
      setState(() => _canApply = canApply);
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Captain sees jamaat applications (includes their own) via main endpoint
      // Member sees own applications via my-applications endpoint
      if (_isCaptain) {
        _applications = await _service.getAllApplications();
      } else {
        _applications = await _service.getMyApplications();
      }
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'submitted_to_admin':
        return Icons.upload_file_rounded;
      case 'sanctioned':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline;
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

  void _handleBackNavigation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await _localStorage.clearAll();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const UnifiedLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _captainApprove(QardanHasanaListItem app) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text(
            'Are you sure you want to approve application ${app.applicationNo} for ${app.applicantName}?\n\nAmount: Rs. ${app.amountRequested.toStringAsFixed(0)}'),
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

    if (confirm == true) {
      try {
        await _service.captainApprove(app.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Application ${app.applicationNo} approved!'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadApplications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Approval failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Premium AppBar ──
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 28),
                      onPressed: _handleBackNavigation,
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                            'assets/images/burhani guards logo.png',
                            height: 52),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_month_outlined,
                              color: Colors.white, size: 26),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BohraCalendarScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white, size: 26),
                          onPressed: _handleLogout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title Section ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF2E7D32).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCaptain
                                  ? 'Qardan Hasana'
                                  : 'Qardan Hasana',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_applications.length} application${_applications.length != 1 ? 's' : ''} found',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Applications List ──
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 48,
                                        color: Colors.red.withOpacity(0.6),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _error!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: _loadApplications,
                                        icon: const Icon(Icons.refresh,
                                            size: 18),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _applications.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons
                                              .account_balance_wallet_outlined,
                                          size: 56,
                                          color: AppColors.primary
                                              .withOpacity(0.2),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _isCaptain
                                              ? 'No applications to review'
                                              : 'No applications yet',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (!_isCaptain) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Apply for Qardan Hasana using the button below',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadApplications,
                                    color: AppColors.primary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: _applications.length,
                                      itemBuilder: (context, index) {
                                        return TweenAnimationBuilder<double>(
                                          tween:
                                              Tween(begin: 0.0, end: 1.0),
                                          duration: Duration(
                                              milliseconds:
                                                  400 + (index * 100)),
                                          curve: Curves.easeOutCubic,
                                          builder:
                                              (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                    0, 20 * (1 - value)),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: _buildApplicationCard(
                                              _applications[index]),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Show Apply FAB for all users (members and captains)
        floatingActionButton: FloatingActionButton.extended(
                onPressed: _canApply
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QardanApplyScreen()),
                        );
                        _loadUserAndApplications();
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You already have an active Qardan Hasana application. You cannot apply again until it is completed or rejected.'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      },
                backgroundColor:
                    _canApply ? AppColors.primary : Colors.grey.shade400,
                foregroundColor: Colors.white,
                icon: Icon(_canApply
                    ? Icons.add_rounded
                    : Icons.block_rounded),
                label: Text(_canApply ? 'Apply' : 'Applied',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
      ),
    );
  }

  Widget _buildApplicationCard(QardanHasanaListItem app) {
    final statusColor = _getStatusColor(app.status);
    final statusLabel = _getStatusLabel(app.status);
    final statusIcon = _getStatusIcon(app.status);

    // Captain approval state
    final bool showCaptainApproval = _isCaptain &&
        app.captainMemberId == _currentUserId &&
        !app.captainApproved &&
        app.status == 'pending';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  QardanDetailScreen(applicationId: app.id)),
        );
        _loadApplications();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showCaptainApproval
                ? AppColors.warning.withOpacity(0.5)
                : Colors.grey.withOpacity(0.1),
            width: showCaptainApproval ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Row: Date + Status + Captain Badge ──
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _formatDate(app.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Captain approval badge (visible to captain)
                      if (_isCaptain) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: app.captainApproved
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                app.captainApproved
                                    ? Icons.verified_rounded
                                    : Icons.pending_actions_rounded,
                                size: 12,
                                color: app.captainApproved
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                app.captainApproved
                                    ? 'Approved'
                                    : 'Awaiting',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Application No + Name (for captain view) ──
                  Text(
                    app.applicationNo,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_isCaptain) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          app.applicantName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),

                  // ── Amount + Mohallah ──
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rs. ${app.amountRequested.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (app.sanctionedAmount != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Sanctioned: Rs. ${app.sanctionedAmount!.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          app.applicantJamaat,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom Action Bar ──
            if (showCaptainApproval)
              // Captain approve button row
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => QardanDetailScreen(
                                    applicationId: app.id)),
                          );
                          _loadApplications();
                        },
                        icon: const Icon(Icons.visibility_rounded,
                            size: 16),
                        label: Text('View',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _captainApprove(app),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 16),
                        label: Text('Approve',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 12),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
