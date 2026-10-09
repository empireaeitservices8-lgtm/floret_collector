import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../viewmodel/home_view_model.dart';
import '../../main/viewmodel/main_view_model.dart';
import '../../schedule/screen/schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/HomeScreen';

  const HomeScreen({super.key});

  void _navigateToSchedule(BuildContext context) {
    try {
      final mainVm = Provider.of<MainViewModel?>(context, listen: false);
      if (mainVm != null) {
        mainVm.setIndex(1);
        return;
      }
    } catch (_) {}
    Navigator.pushNamed(context, ScheduleScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isShimmerLoading) {
                return _buildHomeShimmer();
              }

              final summary = vm.summary;

              final displayName = summary.userName.trim().isNotEmpty
                  ? summary.userName.trim()
                  : 'User';

              return RefreshIndicator(
                onRefresh: () => vm.loadHomeData(isRefresh: true),
                color: const Color(0xFF2E7D32),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Location Header
                      Row(
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 20,
                            color: Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            summary.locationArea,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Greeting Title
                      Text(
                        'Hi, $displayName!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3 Summary KPI Cards in a Row
                      Row(
                        children: [
                          // Card 1: Remaining Covers
                          Expanded(
                            child: _buildMetricCard(
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFD97706),
                              icon: Icons.shopping_bag_rounded,
                              value: summary.remainingCovers,
                              label: 'Remaining Covers',
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Card 2: Weight
                          Expanded(
                            child: _buildMetricCard(
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              icon: Icons.scale_rounded,
                              value: summary.weight,
                              label: 'Weight',
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Card 3: Collected
                          Expanded(
                            child: _buildMetricCard(
                              iconBg: const Color(0xFFDBEAFE),
                              iconColor: const Color(0xFF2563EB),
                              icon: Icons.payments_rounded,
                              value: summary.collectedAmount,
                              label: 'Collected',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Today's Collection Schedule Header & Forward Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => _navigateToSchedule(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "Today's collection schedule",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToSchedule(context),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFDBEAFE),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Schedule Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No collections scheduled for today',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C95A6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Today's Collection Overview Header
                      const Text(
                        "Today's collection overview",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Overview Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Area Row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 18,
                                    color: Color(0xFF1E293B),
                                  ),
                                  const SizedBox(width: 8),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Area: ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: summary.locationArea,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Inner Sanitary Pickups Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Sanitary pickups',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        summary.sanitaryPickups,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Progress Line
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: const SizedBox(
                                      width: double.infinity,
                                      height: 5,
                                      child: LinearProgressIndicator(
                                        value: 0.0,
                                        backgroundColor: Color(0xFFE2E8F0),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF93C5FD),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Completed routes (${summary.routeDescription})',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
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

  Widget _buildHomeShimmer() {
    const baseColor = Color(0xFFE2E8F0);
    const highlightColor = Color(0xFFF8FAFC);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Location Shimmer Row
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 70,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Greeting "Hi, [username]" Shimmer Bar
            Container(
              width: 180,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(height: 20),

            // 3 Summary KPI Cards Shimmer Row
            Row(
              children: [
                Expanded(child: _buildMetricCardShimmer()),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCardShimmer()),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCardShimmer()),
              ],
            ),

            const SizedBox(height: 28),

            // Schedule Header Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 220,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Schedule Card Shimmer
            Container(
              width: double.infinity,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            const SizedBox(height: 28),

            // Overview Header Shimmer
            Container(
              width: 210,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),

            const SizedBox(height: 14),

            // Overview Container Shimmer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCardShimmer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8C95A6),
            ),
          ),
        ],
      ),
    );
  }
}
