import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:flutter/material.dart';
import 'customer_details_card.dart';
import 'disposal_info.dart';
import 'payment_info.dart';

// Top Tabs with Underline Indicator
Widget buildTabs(DirectDisposalViewModel vm) {
  final isNewRecord = vm.selectedTab == DirectDisposalTab.newRecord;

  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    child: Row(
      children: [
        // Tab 1: New Record
        Expanded(
          child: InkWell(
            onTap: () => vm.setSelectedTab(DirectDisposalTab.newRecord),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: isNewRecord
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'New Record',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isNewRecord ? FontWeight.w800 : FontWeight.w600,
                          color: isNewRecord
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 3,
                  width: 110,
                  decoration: BoxDecoration(
                    color: isNewRecord
                        ? const Color(0xFF1E293B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab 2: Disposal Logs
        Expanded(
          child: InkWell(
            onTap: () => vm.setSelectedTab(DirectDisposalTab.disposalLogs),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 18,
                        color: !isNewRecord
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Disposal Logs',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              !isNewRecord ? FontWeight.w800 : FontWeight.w600,
                          color: !isNewRecord
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 3,
                  width: 110,
                  decoration: BoxDecoration(
                    color: !isNewRecord
                        ? const Color(0xFF1E293B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// --- TAB 1: New Record Form ---
Widget buildNewRecordForm({
  required BuildContext context,
  required DirectDisposalViewModel vm,
  required ScrollController scrollController,
  required TextEditingController nameController,
  required TextEditingController phoneController,
  required TextEditingController addressController,
  required TextEditingController descController,
  required TextEditingController weightController,
  final int? remainingBags,
  required TextEditingController rateController,
  required bool isSubmitting,
  required VoidCallback onSubmit,
}) {
  return SingleChildScrollView(
    controller: scrollController,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Customer Details
        buildCustomerDetailsCard(
          vm: vm,
          nameController: nameController,
          phoneController: phoneController,
          addressController: addressController,
        ),

        const SizedBox(height: 16),

        // Card 2: Waste Parameters (Disposal Info)
        buildWasteParametersCard(
          vm: vm,
          descController: descController,
          weightController: weightController,
          rateController: rateController,
        ),

        const SizedBox(height: 16),

        buildBagQuantityCard(vm),
        const SizedBox(height: 16),
        // Card 3: Payment Info & Submit
        buildPaymentInfoCard(
          context: context,
          vm: vm,
          isSubmitting: isSubmitting,
          onSubmit: onSubmit,
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}

Widget buildSectionHeader(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: Color(0xFF1E293B),
    ),
  );
}

Widget buildBagQuantityCard(
  DirectDisposalViewModel vm,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text(
        '  Choose Waste Bag Quantity : ',
        style: const TextStyle(
            fontSize: 12,
            // fontWeight: FontWeight.bold,
            color: Colors.black),
      ),
      IconButton(
        onPressed: vm.decrementBagQuantity,
        icon: const Icon(Icons.remove, color: Colors.black),
        iconSize: 12,
      ),
      const SizedBox(width: 3),
      Text(
        vm.bagQuantity.toString(),
        style: const TextStyle(
            fontSize: 18,
            // fontWeight: FontWeight.bold,
            color: Colors.black),
      ),
      const SizedBox(width: 3),
      IconButton(
        onPressed: vm.incrementBagQuantity,
        icon: const Icon(Icons.add, color: Colors.black),
        iconSize: 12,
      ),
    ],
  );
}
