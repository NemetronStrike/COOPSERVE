import 'package:flutter/material.dart';
import '../../models/complaint_models.dart';
import '../../services/complaint_service.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final _complaintService = ComplaintService();
  List<Complaint>? _complaints;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final complaints = await _complaintService.getAdminComplaints();
      setState(() {
        _complaints = complaints;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _updateStatus(int complaintId, String newStatus) async {
    try {
      await _complaintService.updateComplaintStatus(complaintId, newStatus);
      if (mounted) {
        _loadComplaints();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Complaints Review')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadComplaints, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_complaints == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_complaints!.isEmpty) {
      return const Center(child: Text('No complaints to review.'));
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: ListView.builder(
        itemCount: _complaints!.length,
        itemBuilder: (context, index) {
          final complaint = _complaints![index];
          final bool isCritical = complaint.severity == 'critical' || complaint.severity == 'high';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: isCritical
                ? RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: ExpansionTile(
              title: Text(complaint.summary ?? 'Complaint #${complaint.id}'),
              subtitle: Text(
                'Status: ${complaint.status.toUpperCase()} | AI Category: ${complaint.category.toUpperCase()}',
                style: TextStyle(color: isCritical ? Colors.red.shade700 : null),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Customer ID', complaint.complainantId.toString()),
                      if (complaint.bookingId != null)
                        _buildDetailRow('Booking ID', complaint.bookingId.toString()),
                      _buildDetailRow('Severity', complaint.severity ?? 'N/A'),
                      _buildDetailRow('Urgency', complaint.urgency ?? 'N/A'),
                      _buildDetailRow('Source', complaint.classificationSource ?? 'N/A'),
                      const Divider(),
                      const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(complaint.description),
                      const Divider(),
                      const Text('AI Suggested Action:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(complaint.suggestedAction ?? 'None'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (complaint.status != 'under_review')
                            OutlinedButton(
                              onPressed: () => _updateStatus(complaint.id, 'under_review'),
                              child: const Text('Reviewing'),
                            ),
                          if (complaint.status != 'resolved')
                            ElevatedButton(
                              onPressed: () => _updateStatus(complaint.id, 'resolved'),
                              child: const Text('Mark Resolved'),
                            ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
