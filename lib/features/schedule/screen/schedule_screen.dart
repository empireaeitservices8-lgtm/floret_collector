import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/schedule_view_model.dart';
import '../../main/viewmodel/main_view_model.dart';

class ScheduleScreen extends StatelessWidget {
  static const String routeName = '/ScheduleScreen';

  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScheduleViewModel>(
      create: (_) => ScheduleViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<ScheduleViewModel>(
            builder: (context, vm, _) {
              final schedule = vm.schedule;
              return RefreshIndicator(
                onRefresh: vm.loadSchedule,
                color: const Color(0xFF2E7D32),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Top Bar with Circular Back and Filter Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCircularButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                try {
                                  Provider.of<MainViewModel?>(context, listen: false)?.setIndex(0);
                                } catch (_) {}
                              }
                            },
                          ),
                          const Text(
                            'Collection schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          _buildCircularButton(
                            icon: Icons.tune_rounded,
                            onTap: () {
                              // Filter bottom sheet / action
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // "View your pickups"
                      const Text(
                        'View your pickups',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date Pill: "Wed, 30th Sep"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          schedule.dateText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Today's Progress Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Today's progress",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  schedule.progressText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: double.infinity,
                                height: 5,
                                child: LinearProgressIndicator(
                                  value: schedule.progressPercent,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF93C5FD),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Pickups summary
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sanitary pickups: ${schedule.sanitaryPickups}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.grid_view_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Scrap pickups: ${schedule.scrapPickups}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Waste Type Header
                      Text(
                        'Waste type: ${schedule.wasteType}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      const SizedBox(height: 120),

                      // Empty State Text
                      const Center(
                        child: Text(
                          'No pickups match the selected filters.',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8C95A6),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
