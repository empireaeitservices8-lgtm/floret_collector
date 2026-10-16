import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import '../viewmodel/schedule_view_model.dart';
import 'schedule_filter_bottom_sheet.dart';
import '../../main/viewmodel/main_view_model.dart';
import '../../collection_route/screen/collection_route_screen.dart';

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
                                  Provider.of<MainViewModel?>(context,
                                          listen: false)
                                      ?.setIndex(0);
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
                            icon: Icons.tune,
                            onTap: () {
                              ScheduleFilterBottomSheet.show(
                                context: context,
                                currentFilter: vm.filter,
                                onApply: (newFilter) {
                                  vm.setFilter(newFilter);
                                },
                              );
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

                      // Horizontally scrollable date pills
                      _buildDatePills(vm),

                      const SizedBox(height: 20),

                      // Progress Card for Selected Date
                      _buildProgressCard(vm),

                      const SizedBox(height: 28),

                      // Waste Type Header
                      Text(
                        'Waste type: ${vm.wasteTypeDisplay}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (vm.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        )
                      else if (vm.filteredPickups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Text(
                              vm.pickupsForSelectedDate.isEmpty
                                  ? 'No pickups scheduled for this date.'
                                  : 'No pickups match the selected filters.',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8C95A6),
                              ),
                            ),
                          ),
                        )
                      else
                        ...vm.filteredPickups.map(
                          (pickup) => _buildPickupCard(context, pickup, vm),
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

  Widget _buildDatePills(ScheduleViewModel vm) {
    if (vm.availableDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'Today',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: vm.availableDates.map((dateStr) {
          final isSelected = vm.selectedDate == dateStr;
          final displayText = vm.formatPillDate(dateStr);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => vm.selectDate(dateStr),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressCard(ScheduleViewModel vm) {
    return Container(
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
              Text(
                vm.progressHeaderTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                vm.progressText,
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
                value: vm.progressFraction,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E293B),
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
                'Sanitary pickups: ${vm.sanitaryPickupsText}',
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
                'Scrap pickups: ${vm.scrapPickupsText}',
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

  Widget _buildPickupCard(
    BuildContext context,
    LocationPickupModel pickup,
    ScheduleViewModel vm,
  ) {
    final isArrived = pickup.status.toLowerCase() == 'arrived';
    final statusColor = _statusColor(pickup.status);
    final statusBg = _statusBgColor(pickup.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isArrived
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
          width: isArrived ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickup.street.isNotEmpty ? pickup.street : pickup.city,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isArrived
                          ? Icons.check_circle_rounded
                          : Icons.flag_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _capitalize(pickup.status),
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
              pickup.pickupTimeSlot,
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
              'Pickup type: ${_wasteTypeShort(pickup.wasteType)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isArrived) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final routeName =
                      pickup.street.isNotEmpty ? pickup.street : pickup.city;
                  Navigator.pushNamed(
                    context,
                    CollectionRouteScreen.routeName,
                    arguments: {
                      'routeName': routeName,
                      'address': routeName,
                      'time': pickup.pickupTimeSlot,
                      'type': pickup.wasteType,
                      'pickupId': pickup.pickupId,
                      'hasArrived': true,
                      'status': 'arrived',
                    },
                  ).then((_) => vm.refresh());
                },
                icon: const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: Colors.white),
                label: const Text(
                  'Make collection',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'picked':
      case 'collected':
      case 'completed':
        return const Color(0xFF16A34A);
      case 'arrived':
        return const Color(0xFF059669);
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
        return const Color(0xFFD1FAE5);
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
