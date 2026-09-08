import 'package:flutter/material.dart';
import '../../models/complaint_models.dart';
import '../../services/complaint_service.dart';

class ComplaintCreateScreen extends StatefulWidget {
  final int? bookingId;
  const ComplaintCreateScreen({super.key, this.bookingId});

  @override
  State<ComplaintCreateScreen> createState() => _ComplaintCreateScreenState();
}

class _ComplaintCreateScreenState extends State<ComplaintCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _complaintService = ComplaintService();
  bool _isLoading = false;
  Complaint? _result;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final complaint = await _complaintService.createComplaint(
        _descriptionController.text.trim(),
        bookingId: widget.bookingId,
      );
      setState(() {
        _result = complaint;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_result != null)
              _buildSuccessResult()
            else ...[
              const Text(
                'Please describe the issue in detail. Our AI will analyze your complaint and flag it for admin review.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Please provide more details (at least 5 characters).';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Complaint'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessResult() {
    final complaint = _result!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complaint Submitted Successfully',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text('AI Classification Result', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildResultRow('Category', complaint.category),
            _buildResultRow('Severity', complaint.severity ?? 'N/A'),
            _buildResultRow('Urgency', complaint.urgency ?? 'N/A'),
            if (complaint.summary != null) ...[
              const SizedBox(height: 8),
              const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint.summary!),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Return to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
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
