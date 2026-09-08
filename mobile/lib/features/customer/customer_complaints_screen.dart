import 'package:flutter/material.dart';
import '../../models/complaint_models.dart';
import '../../services/complaint_service.dart';

class CustomerComplaintsScreen extends StatefulWidget {
  const CustomerComplaintsScreen({super.key});

  @override
  State<CustomerComplaintsScreen> createState() => _CustomerComplaintsScreenState();
}

class _CustomerComplaintsScreenState extends State<CustomerComplaintsScreen> {
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
      final complaints = await _complaintService.getCustomerComplaints();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/customer/complaints/create').then((_) => _loadComplaints());
        },
        tooltip: 'Report a Complaint',
        child: const Icon(Icons.add),
      ),
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
      return const Center(child: Text('You have no complaints.'));
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: ListView.builder(
        itemCount: _complaints!.length,
        itemBuilder: (context, index) {
          final complaint = _complaints![index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(complaint.summary ?? 'Complaint #${complaint.id}'),
              subtitle: Text(
                'Status: ${complaint.status.toUpperCase()} | Date: ${complaint.createdAt.toLocal().toString().split(' ')[0]}',
              ),
              trailing: Chip(
                label: Text(complaint.severity?.toUpperCase() ?? 'N/A'),
                backgroundColor: _getSeverityColor(complaint.severity),
              ),
              onTap: () {
                _showComplaintDetails(complaint);
              },
            ),
          );
        },
      ),
    );
  }

  Color? _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical': return Colors.red.shade300;
      case 'high': return Colors.orange.shade300;
      case 'medium': return Colors.amber.shade300;
      case 'low': return Colors.green.shade300;
      default: return Colors.grey.shade300;
    }
  }

  void _showComplaintDetails(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complaint Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', complaint.category),
              _buildDetailRow('Status', complaint.status),
              _buildDetailRow('Severity', complaint.severity ?? 'N/A'),
              _buildDetailRow('Urgency', complaint.urgency ?? 'N/A'),
              const Divider(),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint.description),
              if (complaint.resolutionNotes != null) ...[
                const Divider(),
                const Text('Resolution Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(complaint.resolutionNotes!),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
