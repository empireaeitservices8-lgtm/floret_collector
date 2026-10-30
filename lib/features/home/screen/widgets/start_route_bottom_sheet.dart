import 'package:flutter/material.dart';

class StartRouteBottomSheet extends StatelessWidget {
  final String route;
  final String time;
  final String type;
  final VoidCallback? onConfirm;

  const StartRouteBottomSheet({
    super.key,
    required this.route,
    required this.time,
    required this.type,
    this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String route,
    required String time,
    required String type,
    VoidCallback? onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => StartRouteBottomSheet(
        route: route,
        time: time,
        type: type,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F5F2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Transform.rotate(
                  angle: 1.0,
                  child: const Icon(
                    Icons.navigation_sharp,
                    size: 26,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Start route?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Once you start the route, the pickup list will be activated and cannot be changed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Route Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Route',
                    value: route.isNotEmpty ? route : 'N/A',
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    label: 'Time',
                    value: time.isNotEmpty ? time : 'N/A',
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    label: 'Type',
                    value: type.isNotEmpty ? type : 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
