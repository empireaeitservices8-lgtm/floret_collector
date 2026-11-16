import 'package:floret_collector/features/direct_disposal/model/direct_disposal_model.dart';
import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:flutter/material.dart';

Widget buildDisposalLogsList({
  required DirectDisposalViewModel vm,
  required TextEditingController searchController,
}) {
  final logs = vm.filteredLogs;

  return Column(
    children: [
      // Search Bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: searchController,
            onChanged: vm.setSearchQuery,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search by Customer Name, Phone, or Waste Type...',
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
                        searchController.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ),

      // Logs List
      Expanded(
        child: logs.isEmpty
            ? const Center(
                child: Text(
                  'No Disposal Logs Found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final item = logs[index];
                  return buildLogCard(item);
                },
              ),
      ),
    ],
  );
}

Widget buildLogCard(DirectDisposalLogModel item) {
  final isPaid = item.isPaid;

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
        // Top Row: Avatar/Icon + Customer Name & Phone + Status Badge
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_pin_circle_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Phone: ${item.phone}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.paymentStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isPaid
                      ? const Color(0xFF15803D)
                      : const Color(0xFF92400E),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
        const SizedBox(height: 12),

        // Middle Row: 4 Columns (Waste Type | Weight | GST (5%) | Total Paid)
        Row(
          children: [
            // Waste Type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waste Type',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.wasteType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            // GST
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GST (${item.gstRatePercent.toInt()}%)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.gstAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            // Total Paid
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Paid',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
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

        // Bottom Row: Date + Method
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.formattedDate,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.paymentMethod.toUpperCase() == 'ONLINE'
                      ? Icons.credit_card_outlined
                      : Icons.money_outlined,
                  size: 16,
                  color: const Color(0xFF0F172A),
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
