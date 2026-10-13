import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:floret_collector/core/di/injection.dart';
import '../model/collection_history_model.dart';
import '../viewmodel/collection_history_view_model.dart';
import 'collection_filter_bottom_sheet.dart';

class CollectionHistoryScreen extends StatefulWidget {
  static const String routeName = '/CollectionHistoryScreen';

  const CollectionHistoryScreen({super.key});

  @override
  State<CollectionHistoryScreen> createState() =>
      _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CollectionHistoryViewModel>(
      create: (_) => getIt.isRegistered<CollectionHistoryViewModel>()
          ? getIt<CollectionHistoryViewModel>()
          : CollectionHistoryViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Consumer<CollectionHistoryViewModel>(
            builder: (context, vm, _) {
              final summary = vm.effectiveSummary;
              final history = vm.filteredHistory;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Top App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                          tooltip: 'Back',
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Collection History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: vm.loadHistory,
                          onLongPress: () {
                            // Quick toggle for testing timeout error state (Image 5)
                            vm.toggleTimeoutForTesting();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  vm.isTimeoutError
                                      ? 'Restoring normal collection history...'
                                      : 'Simulating connection timeout...',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.black,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                          tooltip: 'Refresh (Long press to test timeout)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Top Summary Card (Dark Navy)
                  _buildSummaryCard(summary),

                  const SizedBox(height: 10),

                  // Search Bar + Filter Button
                  _buildSearchAndFilterRow(context, vm),

                  // Active Filter Chips (if any filter is selected)
                  if (vm.filter.hasFilters) ...[
                    const SizedBox(height: 8),
                    _buildActiveFiltersRow(vm),
                  ],

                  const SizedBox(height: 10),

                  // Body Content: Shimmer (3s) | Timeout Error | Empty State | History List
                  Expanded(
                    child: vm.isShimmering
                        ? _buildShimmerLoadingList()
                        : vm.isTimeoutError
                            ? _buildTimeoutErrorState(vm)
                            : history.isEmpty
                                ? _buildEmptyState(vm)
                                : _buildHistoryList(history),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Top Dark Navy Summary Card
  Widget _buildSummaryCard(CollectionSummaryModel summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Column 1: Total Stops
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.totalStops}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total Stops',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 38,
            width: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // Column 2: Weight
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.scale_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.totalWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 38,
            width: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // Column 3: Amount
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${summary.totalAmount.toInt()}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar + Filter Button
  Widget _buildSearchAndFilterRow(
    BuildContext context,
    CollectionHistoryViewModel vm,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: vm.setSearchQuery,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Stop ID or Waste Type...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  suffixIcon: vm.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Filter Button with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  CollectionFilterBottomSheet.show(
                    context: context,
                    currentFilter: vm.filter,
                    onApply: vm.applyFilters,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                  ),
                ),
              ),
              if (vm.filter.activeFilterCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${vm.filter.activeFilterCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Active Filter Chips Horizontal Row
  Widget _buildActiveFiltersRow(CollectionHistoryViewModel vm) {
    final filter = vm.filter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (filter.wasteType != 'All') ...[
            _buildActiveChip(
              label: 'Type: ${filter.wasteType}',
              onDelete: vm.removeWasteTypeFilter,
            ),
            const SizedBox(width: 8),
          ],
          if (filter.paymentStatus != 'All') ...[
            _buildActiveChip(
              label: 'Status: ${filter.paymentStatus}',
              onDelete: vm.removeStatusFilter,
            ),
            const SizedBox(width: 8),
          ],
          if (filter.paymentMethod != 'All') ...[
            _buildActiveChip(
              label: 'Method: ${filter.paymentMethod}',
              onDelete: vm.removeMethodFilter,
            ),
            const SizedBox(width: 8),
          ],
          if (filter.dateRange != null) ...[
            _buildActiveChip(
              label:
                  'Date: ${DateFormat('dd MMM').format(filter.dateRange!.start)} - ${DateFormat('dd MMM').format(filter.dateRange!.end)}',
              onDelete: vm.removeDateRangeFilter,
            ),
            const SizedBox(width: 8),
          ],

          // Clear All Button (Image 4)
          InkWell(
            onTap: vm.clearAllFilters,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFF1E1B4B),
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer Skeleton List (Image 1) - Shown for 3 seconds on load/refresh
  Widget _buildShimmerLoadingList() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 130,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white),
              const SizedBox(height: 12),

              // Middle Row (3 Items)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white),
              const SizedBox(height: 12),

              // Bottom Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // History List (Image 2)
  Widget _buildHistoryList(List<CollectionItemModel> history) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(CollectionItemModel item) {
    final isPaid = item.status.toUpperCase() == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Mint Green Truck Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Stop Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop ID: #${item.stopId} • ${item.stopName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.wasteType,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPaid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Details Row (Weight, Rate, Amount)
          Row(
            children: [
              // Weight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              // Rate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.rate.toStringAsFixed(1)}/kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          const SizedBox(height: 10),

          // Footer Row (Date & Payment Method)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.date,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Empty State (Image 4): "No Collection Logs Found"
  Widget _buildEmptyState(CollectionHistoryViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mint Green Round History Clock Icon
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F9F0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.history_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Collection Logs Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Start confirming collection routes and recording pickups to view your logs here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF94A3B8),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error State / Connection Timeout (Image 5): "Failed to Load History"
  Widget _buildTimeoutErrorState(CollectionHistoryViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Red Outline Circular Icon with !
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444), width: 2.5),
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Failed to Load History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              vm.errorMessage.isNotEmpty
                  ? vm.errorMessage
                  : 'ClientException with SocketConnection timed out (OS Error: Connection timed out, errno = 110), address = florettech.pythonanywhere.com, port = 52088, uri=https://florettech.pythonanywhere.com/api/collector-history/?collector_id=68',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            // Retry Button
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: vm.retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
