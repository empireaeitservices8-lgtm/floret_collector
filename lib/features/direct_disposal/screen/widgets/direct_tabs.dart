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
        // Section 1: Choose Waste Bag Quantity
        buildSectionHeader('1. Choose Waste Bag Quantity'),
        const SizedBox(height: 8),
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
  DirectDisposalViewModel viewModel,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Waste Bag',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: viewModel.remainingBags > 0
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${viewModel.remainingBags} Remaining',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: viewModel.remainingBags > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                viewModel.bagPriceLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Remaining bags available: ${viewModel.remainingBags}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: viewModel.remainingBags > 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: viewModel.bagQuantity > 0
                  ? viewModel.decrementBagQuantity
                  : null,
              icon: const Icon(Icons.remove_circle_outline, size: 24),
              color: const Color(0xFF1E293B),
              disabledColor: const Color(0xFFCBD5E1),
            ),
            Text(
              '${viewModel.bagQuantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            IconButton(
              onPressed: viewModel.canIncrementBag
                  ? viewModel.incrementBagQuantity
                  : null,
              icon: const Icon(Icons.add_circle_outline, size: 24),
              color: const Color(0xFF1E293B),
              disabledColor: const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ],
    ),
  );
}
