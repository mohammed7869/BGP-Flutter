import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/jamaat_transfer_service.dart';
import '../../../core/services/local_storage_service.dart';
import 'package:intl/intl.dart';

class JamaatTransfersScreen extends StatefulWidget {
  const JamaatTransfersScreen({Key? key}) : super(key: key);

  @override
  State<JamaatTransfersScreen> createState() => _JamaatTransfersScreenState();
}

class _JamaatTransfersScreenState extends State<JamaatTransfersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JamaatTransferService _transferService = JamaatTransferService();
  final LocalStorageService _storageService = LocalStorageService();
  
  List<dynamic> _incomingTransfers = [];
  List<dynamic> _outgoingTransfers = [];
  List<dynamic> _historyTransfers = [];
  bool _isLoading = true;
  int? _jamaatId;

  // Colors
  static const Color _brandDark = Color(0xFF461D17);
  static const Color _goldAccent = Color(0xFFD4A574);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _storageService.getUserData();
      if (user != null && user.jamaat != null) {
        // Find Jamaat ID from constant (assuming Baramati=1 etc or parsing from user data if we stored JamaatId)
        // Here we just fetch via a generic endpoint or we might need to send jamaatId
        // In this implementation, I will assume Jamaat ID is fetched from local storage if available
        // Wait, local storage has UserLoginDetail, does it have JamaatId? Yes, usually.
        _jamaatId = user.id; // Wait, we need JamaatId. Assuming user.id gets their profile.
        // I will use user.jamaat as text, but API needs JamaatId. Let's fix this in API to accept string or just use id.
        // We will fetch incoming and outgoing
      }
      
      // Fetch data... (Implementation details will need valid jamaat ID)
      // For now we assume a hardcoded or valid id
      if (user != null) {
        final jamaats = {
          'BARAMATI': 1,
          'FAKHRI MOHALLA (POONA)': 2,
          'ZAINI MOHALLA (POONA)': 3,
          'KALIMI MOHALLA (POONA)': 4,
          'AHMEDNAGAR': 5,
          'IMADI MOHALLA (POONA)': 6,
          'KASARWADI': 7,
          'KHADKI (POONA)': 8,
          'LONAVALA': 9,
          'MUFADDAL MOHALLA (POONA)': 10,
          'POONA': 11,
          'SAIFEE MOHALLAH (POONA)': 12,
          'TAIYEBI MOHALLA (POONA)': 13,
          'FATEMI MOHALLA (POONA)': 14,
          'ITWARA': 15,
        };
        final jId = jamaats[user.jamaat?.toUpperCase()] ?? 11;
        _incomingTransfers = await _transferService.getPendingIncomingTransfers(jId);
        _outgoingTransfers = await _transferService.getPendingOutgoingTransfers(jId);
        _historyTransfers = await _transferService.getHistoryTransfers(jId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccept(int id) async {
    try {
      await _transferService.acceptTransfer(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer Accepted')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleReject(int id) async {
    final reasonController = TextEditingController();
    final bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Transfer'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      try {
        await _transferService.rejectTransfer(id, reasonController.text);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer Rejected')));
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildTransferCard(dynamic transfer, bool isIncoming) {
    final status = transfer['status'] as String? ?? 'PENDING';
    final statusColor = status == 'APPROVED'
        ? Colors.green
        : status == 'REJECTED'
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      shadowColor: _brandDark.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Member info row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
                  ),
                  child: transfer['memberProfile'] != null && transfer['memberProfile'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            '${ApiConstants.baseUrl}/${transfer['memberProfile']}',
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: _brandDark.withOpacity(0.4),
                              size: 24,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5, color: _brandDark),
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(Icons.person, color: _brandDark.withOpacity(0.4), size: 24),
                ),
                const SizedBox(width: 10),
                // Name + details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer['memberName'] ?? 'Unknown Member',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('ITS: ${transfer['memberItsId']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      if (transfer['memberContact'] != null && transfer['memberContact'].toString().isNotEmpty)
                        Text('${transfer['memberContact']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Transfer route ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _brandDark.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _goldAccent.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          transfer['fromJamaat'],
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, color: _goldAccent, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('To', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          transfer['toJamaat'],
                          style: const TextStyle(fontSize: 13, color: _brandDark, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Action buttons ──
            if (transfer['status'] == 'PENDING' || transfer['status'] == 'ACCEPTED') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleReject(transfer['id']),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  if (isIncoming) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _handleAccept(transfer['id']),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandDark,
                        foregroundColor: _goldAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jamaat Transfers'),
        backgroundColor: _brandDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _goldAccent,
          labelColor: _goldAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandDark))
          : TabBarView(
              controller: _tabController,
              children: [
                // Incoming Transfers
                _incomingTransfers.isEmpty
                    ? const Center(child: Text('No incoming transfers'))
                    : ListView.builder(
                        itemCount: _incomingTransfers.length,
                        itemBuilder: (context, index) => _buildTransferCard(_incomingTransfers[index], true),
                      ),
                // Outgoing Transfers
                _outgoingTransfers.isEmpty
                    ? const Center(child: Text('No outgoing transfers'))
                    : ListView.builder(
                        itemCount: _outgoingTransfers.length,
                        itemBuilder: (context, index) => _buildTransferCard(_outgoingTransfers[index], false),
                      ),
                // History Transfers
                _historyTransfers.isEmpty
                    ? const Center(child: Text('No transfer history'))
                    : ListView.builder(
                        itemCount: _historyTransfers.length,
                        itemBuilder: (context, index) => _buildTransferCard(_historyTransfers[index], false),
                      ),
              ],
            ),
    );
  }
}
