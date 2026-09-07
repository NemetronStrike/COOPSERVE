import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_text_styles.dart';
import '../../models/transaction_models.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class RatingScreen extends StatefulWidget {
  final int bookingId;
  final String workerName;
  final Future<RatingRecord> Function({
    required int rating,
    required String review,
  })
  submit;

  RatingScreen({
    super.key,
    required this.bookingId,
    required this.workerName,
    Future<RatingRecord> Function({
      required int rating,
      required String review,
    })?
    submit,
  }) : submit =
           submit ??
           (({required rating, required review}) =>
               BookingService().submitRating(
                 bookingId: bookingId,
                 rating: rating,
                 review: review,
               ));

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Worker')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppCard(
            child: Column(
              children: [
                Text(
                  'How was your service with ${widget.workerName}?',
                  style: AppTextStyles.titleLarge(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: '$value stars',
                      onPressed: () => setState(() => _rating = value),
                      icon: Icon(
                        value <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 38,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review (optional)',
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Submit Review',
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Select a star rating first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.submit(
        rating: _rating,
        review: _reviewController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}
