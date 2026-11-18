import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickupCalendar extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final ValueChanged<DateTimeRange?> onDateRangeSelected;

  const PickupCalendar({
    super.key,
    this.initialDateRange,
    required this.onDateRangeSelected,
  });

  @override
  State<PickupCalendar> createState() => _PickupCalendarState();
}

class _PickupCalendarState extends State<PickupCalendar> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialDateRange;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E293B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _applyQuickOption(String option) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (option) {
      case 'Today':
        setState(() {
          _selectedDateRange = DateTimeRange(start: today, end: today);
        });
        break;
      case 'Yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        setState(() {
          _selectedDateRange =
              DateTimeRange(start: yesterday, end: yesterday);
        });
        break;
      case 'Last 7 Days':
        final sevenDaysAgo = today.subtract(const Duration(days: 6));
        setState(() {
          _selectedDateRange = DateTimeRange(start: sevenDaysAgo, end: today);
        });
        break;
      case 'This Month':
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        setState(() {
          _selectedDateRange =
              DateTimeRange(start: firstDayOfMonth, end: today);
        });
        break;
    }
  }

  void _reset() {
    setState(() {
      _selectedDateRange = null;
    });
    widget.onDateRangeSelected(null);
    Navigator.pop(context);
  }

  void _apply() {
    widget.onDateRangeSelected(_selectedDateRange);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final quickOptions = ['Today', 'Yesterday', 'Last 7 Days', 'This Month'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Disposal Logs',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Presets
                const Text(
                  'Quick Presets',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickOptions.map((opt) {
                    return ActionChip(
                      label: Text(
                        opt,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () => _applyQuickOption(opt),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Section: Date Range
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedDateRange != null
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: _selectedDateRange != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: _selectedDateRange != null
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDateRange != null
                                ? '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)}  –  ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
                                : 'Select Custom Date Range',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedDateRange != null
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                              fontWeight: _selectedDateRange != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDateRange = null;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.cancel,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions: Reset & Apply
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filter',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
