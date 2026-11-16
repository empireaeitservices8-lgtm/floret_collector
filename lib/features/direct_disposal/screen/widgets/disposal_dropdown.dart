import 'package:flutter/material.dart';

Widget buildDisposalDropdown({
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.arrow_drop_down_rounded,
          color: Color(0xFF64748B),
        ),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}
