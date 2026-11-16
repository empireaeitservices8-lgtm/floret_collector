import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:flutter/material.dart';
import 'disposal_dropdown.dart';

Widget buildWasteParametersCard({
  required DirectDisposalViewModel vm,
  required TextEditingController descController,
  required TextEditingController weightController,
  required TextEditingController rateController,
}) {
  return Container(
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
        // Header: Green scale icon + Title
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F9F0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.scale_outlined,
                  color: Color(0xFF10B981),
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Waste Parameters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
        const SizedBox(height: 14),

        // Row: Disposal Type + Waste Type
        Row(
          children: [
            // Disposal Type Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disposal Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  buildDisposalDropdown(
                    value: vm.disposalType,
                    items: vm.disposalTypeOptions,
                    onChanged: (val) {
                      if (val != null) vm.setDisposalType(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Waste Type Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waste Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  buildDisposalDropdown(
                    value: vm.wasteType,
                    items: vm.wasteTypeOptions,
                    onChanged: (val) {
                      if (val != null) vm.setWasteType(val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Waste Description (Optional)
        const Text(
          'Waste Description',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: descController,
            onChanged: vm.setWasteDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Describe waste details (optional)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.description_outlined,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Row: Weight (kg) + Disposal Rate (₹/kg)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weight (kg)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weight (kg)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: vm.weightError != null
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0.0;
                        vm.setWeight(parsed);
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        prefixIcon: Icon(
                          Icons.scale_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      ),
                    ),
                  ),
                  if (vm.weightError != null) ...[
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        vm.weightError!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Disposal Rate (₹/kg)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disposal Rate (₹/kg)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: rateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0.0;
                        vm.setRate(parsed);
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        prefixIcon: Center(
                          widthFactor: 1.2,
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
