import 'package:floret_collector/features/home/model/location_pickup_model.dart';
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
      create: (_) {
        final vm = getIt<HomeViewModel>();
        vm.loadCollector().then((_) => vm.loadBagAssignment());
        vm.loadLocations();
        vm.loadBags();
        vm.loadPickupSlots();
        return vm;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return buildHomeShimmer();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    vm.loadPickupSlots(),
                    vm.loadBagAssignment(),
                    vm.loadLocations(),
                    vm.loadBags(),
                  ]);
                },
                color: const Color(0xFF2E7D32),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Location Header ──
                      Row(
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 18,
                            color: Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vm.localBodyName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // ── Greeting ──
                      Text(
                        'Hi, ${vm.collectorName.isEmpty ? 'Collector' : vm.collectorName}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── KPI Cards ──
                      Row(
                        children: [
                          // Remaining Covers
                          Expanded(
                            child: buildMetricCard(
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFD97706),
                              icon: Icons.shopping_bag_rounded,
                              value: '${vm.remainingBags}/${vm.assignedBags}',
                              label: 'Remaining Covers',
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Weight
                          Expanded(
                            child: buildMetricCard(
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              icon: Icons.scale_rounded,
                              value: '0.0 kg',
                              label: 'Weight',
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Collected
                          Expanded(
                            child: buildMetricCard(
                              iconBg: const Color(0xFFDBEAFE),
                              iconColor: const Color(0xFF2563EB),
                              icon: Icons.payments_rounded,
                              value: '₹0',
                              label: 'Collected',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Next Collection Route ──
                      _buildNextRouteCard(context, vm),
                      const SizedBox(height: 24),

                      // ── Today's Collection Schedule ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's collection schedule",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          InkWell(
                            onTap: () => _navigateToSchedule(context),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFDBEAFE),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Schedule items from locations API
                      if (vm.todayLocations.isEmpty)
                        _buildEmptySchedule()
                      else
                        ...vm.todayLocations
                            .map((loc) => _buildScheduleCard(loc)),

                      const SizedBox(height: 24),

                      // ── Today's Collection Overview ──
                      const Text(
                        "Today's collection overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCollectionOverview(vm),
                      const SizedBox(height: 28),
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

  // ── Next Collection Route Card ──
  Widget _buildNextRouteCard(BuildContext context, HomeViewModel vm) {
    final next = vm.nextPickup;

    // All today's pending pickups are done
    if (next == null) {
      return Container(
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
            const Text(
              'Next collection route',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 26, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'All routes done for today!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No more pending pickups',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Container(
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
          const Text(
            'Next collection route',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          // Route row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              const Text(
                'Route:  ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (next.street.isNotEmpty ? next.street : next.city),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // if (next != null && next.name.isNotEmpty) ...[
                    //   const SizedBox(height: 2),
                    //   Text(
                    //     next.name,
                    //     style: const TextStyle(
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.w500,
                    //       color: Color(0xFF64748B),
                    //     ),
                    //     overflow: TextOverflow.ellipsis,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Type row
          Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              const Text(
                'Type:  ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                next.wasteType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Start Route Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Start route',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                disabledBackgroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Schedule Card ──
  Widget _buildScheduleCard(LocationPickupModel loc) {
    final statusColor = _statusColor(loc.status);
    final statusBg = _statusBgColor(loc.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: Color(0xFF475569)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.street.isNotEmpty ? loc.street : loc.city,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      _capitalize(loc.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              loc.pickupTimeSlot,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'Pickup type: ${_wasteTypeShort(loc.wasteType)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'No collections scheduled for today',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8C95A6), fontSize: 14),
        ),
      ),
    );
  }

  // ── Collection Overview Card ──
  Widget _buildCollectionOverview(HomeViewModel vm) {
    final totalToday = vm.todaySanitaryTotal;
    final completed = vm.todaySanitaryCompleted;
    final progress = totalToday > 0 ? completed / totalToday : 0.0;

    // Build ward area label
    final areaLabel = vm.todayLocations.isNotEmpty
        ? vm.todayLocations.first.ward
        : vm.localBodyName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 18, color: Color(0xFF1E293B)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Area: ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      children: [
                        TextSpan(
                          text: areaLabel.isNotEmpty
                              ? areaLabel
                              : 'No pickups today',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sanitary pickups inner card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sanitary pickups',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      totalToday > 0 ? '$completed/$totalToday' : '0/0',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 5,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF93C5FD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Completed routes (Organic & domestic bio-waste)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'picked':
      case 'collected':
      case 'completed':
        return const Color(0xFF16A34A);
      case 'arrived':
        return const Color(0xFF2563EB);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'picked':
      case 'collected':
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'arrived':
        return const Color(0xFFDBEAFE);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _wasteTypeShort(String wasteType) {
    if (wasteType.toLowerCase().contains('sanitary')) return 'Sanitary';
    if (wasteType.toLowerCase().contains('scrap')) return 'Scrap';
    return wasteType;
  }
}
