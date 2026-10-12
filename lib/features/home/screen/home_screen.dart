import 'package:floret_collector/features/home/screen/widgets/home_shimmer.dart';
import 'package:floret_collector/features/home/screen/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_view_model.dart';
import 'package:floret_collector/core/di/injection.dart';
import '../../main/viewmodel/main_view_model.dart';
import '../../schedule/screen/schedule_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/HomeScreen';

  const HomeScreen({super.key});

  Widget _scheduleMessage(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
            child: Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Color(0xFF8C95A6), fontSize: 15))),
      );

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
      create: (_) => getIt<HomeViewModel>()
        ..loadCollector()
        ..loadBags()
        ..loadPickupSlots(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return buildHomeShimmer();
              }

              final summary = _DashboardPlaceholder();

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    vm.loadPickupSlots(),
                    vm.loadBags(),
                  ]);
                },
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
                        'Hi, ${vm.collectorName.isEmpty ? "Collector" : vm.collectorName}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      //  Summary KPI Cards in a Row
                      Row(
                        children: [
                          // Card 1: Remaining Covers
                          Expanded(
                            child: buildMetricCard(
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
                            child: buildMetricCard(
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
                            child: buildMetricCard(
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
                      // Schedule Card: real data from /api/pickup-slots/
                      if (vm.errorMessage != null)
                        _scheduleMessage(vm.errorMessage!)
                      else if (vm.todaySlots.isEmpty)
                        _scheduleMessage('No collections scheduled for today')
                      else
                        ...vm.todaySlots.map((slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(slot.localBody,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('${slot.district} • ${slot.timeSlot}',
                                        style: const TextStyle(
                                            color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    Text(
                                        'Available spots: ${slot.availableSpots}',
                                        style: const TextStyle(
                                            color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            )),
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
}

// Display-only defaults.
class _DashboardPlaceholder {
  final String userName = 'Collector';
  final String locationArea = 'N/A';
  final String remainingCovers = '0/0';
  final String weight = '0.0 kg';
  final String collectedAmount = '₹0';
  final String sanitaryPickups = '0/0';
  final String routeDescription = 'Organic & domestic bio-waste';
}
