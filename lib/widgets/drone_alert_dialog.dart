import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class DroneAlertDialog extends StatelessWidget {
  final VoidCallback onSendSignal;
  final VoidCallback onDismiss;

  const DroneAlertDialog({
    super.key,
    required this.onSendSignal,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, {
    required VoidCallback onSendSignal,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DroneAlertDialog(
        onSendSignal: onSendSignal,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.flight_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🚁 Rescue Drone Nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A rescue drone has been detected in your area. Send your emergency signal now to alert rescuers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onSendSignal();
                  onDismiss();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.onTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Send Emergency Signal',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Dismiss',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
