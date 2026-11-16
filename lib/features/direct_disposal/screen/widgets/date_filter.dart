import 'package:floret_collector/features/collection_history/model/collection_summary_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionFilterBottomSheet extends StatefulWidget {
  final CollectionFilterModel initialFilter;
  final ValueChanged<CollectionFilterModel> onApply;

  const CollectionFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required CollectionFilterModel currentFilter,
    required ValueChanged<CollectionFilterModel> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionFilterBottomSheet(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CollectionFilterBottomSheet> createState() =>
      _CollectionFilterBottomSheetState();
}

class _CollectionFilterBottomSheetState
    extends State<CollectionFilterBottomSheet> {
  late DateTimeRange? _selectedDateRange;
  late String _selectedWasteType;
  late String _selectedPaymentStatus;
  late String _selectedPaymentMethod;

  final List<String> _wasteTypeOptions = const [
    'All',
    'Household',
    'Sanitary Waste',
    'Mixed waste',
    'Bio waste',
    'Dry waste',
    'Wet waste',
    'Hazardous',
  ];

  final List<String> _paymentStatusOptions = const [
    'All',
    'Paid',
    'Pending',
  ];

  final List<String> _paymentMethodOptions = const [
    'All',
    'Cash',
    'Online',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialFilter.dateRange;
    _selectedWasteType = widget.initialFilter.wasteType;
    _selectedPaymentStatus = widget.initialFilter.paymentStatus;
    _selectedPaymentMethod = widget.initialFilter.paymentMethod;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = DateTime(now.year + 2);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.white,
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

  void _resetAll() {
    setState(() {
      _selectedDateRange = null;
      _selectedWasteType = 'All';
      _selectedPaymentStatus = 'All';
      _selectedPaymentMethod = 'All';
    });
  }

  void _apply() {
    final newFilter = CollectionFilterModel(
      dateRange: _selectedDateRange,
      wasteType: _selectedWasteType,
      paymentStatus: _selectedPaymentStatus,
      paymentMethod: _selectedPaymentMethod,
    );
    widget.onApply(newFilter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  'Filter Collection History',
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

          const SizedBox(height: 8),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
                                  : 'Select Date Range',
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
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Waste Type
                  const Text(
                    'Waste Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _wasteTypeOptions.map((type) {
                      final isSelected = _selectedWasteType == type;
                      return _buildSelectableChip(
                        label: type,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedWasteType = type;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Section: Payment Status
                  const Text(
                    'Payment Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _paymentStatusOptions.map((status) {
                      final isSelected = _selectedPaymentStatus == status;
                      return _buildSelectableChip(
                        label: status,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedPaymentStatus = status;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Section: Payment Method
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _paymentMethodOptions.map((method) {
                      final isSelected = _selectedPaymentMethod == method;
                      return _buildSelectableChip(
                        label: method,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = method;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _resetAll,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Reset All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                        'Apply Filters',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
