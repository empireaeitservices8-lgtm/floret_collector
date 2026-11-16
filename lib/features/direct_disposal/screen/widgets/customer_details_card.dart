import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:flutter/material.dart';

Widget buildCustomerDetailsCard({
  required DirectDisposalViewModel vm,
  required TextEditingController nameController,
  required TextEditingController phoneController,
  required TextEditingController addressController,
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
        // Header: Blue person icon + Title
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF2563EB),
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Customer Details',
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

        // Customer Name Field
        const Text(
          'Customer Name',
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
              color: vm.nameError != null
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: nameController,
            onChanged: vm.setCustomerName,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter customer full name',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.badge_outlined,
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
        if (vm.nameError != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              vm.nameError!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Phone Number Field
        const Text(
          'Phone Number',
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
              color: vm.phoneError != null
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            onChanged: vm.setPhone,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter 10-digit phone number',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
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
        if (vm.phoneError != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              vm.phoneError!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Customer Address Field
        const Text(
          'Customer Address',
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
              color: vm.addressError != null
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: addressController,
            onChanged: vm.setCustomerAddress,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter residential address',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.home_outlined,
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
        if (vm.addressError != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              vm.addressError!,
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
  );
}
