import 'package:flutter/material.dart';
import '../model/schedule_filter_model.dart';

class ScheduleFilterBottomSheet extends StatefulWidget {
  final ScheduleFilterModel initialFilter;
  final ValueChanged<ScheduleFilterModel> onApply;

  const ScheduleFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required ScheduleFilterModel currentFilter,
    required ValueChanged<ScheduleFilterModel> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => ScheduleFilterBottomSheet(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ScheduleFilterBottomSheet> createState() =>
      _ScheduleFilterBottomSheetState();
}

class _ScheduleFilterBottomSheetState extends State<ScheduleFilterBottomSheet> {
  late PickupTypeFilter _selectedPickupType;
  late CollectionStatusFilter _selectedCollectionStatus;

  @override
  void initState() {
    super.initState();
    _selectedPickupType = widget.initialFilter.pickupType;
    _selectedCollectionStatus = widget.initialFilter.collectionStatus;
  }

  void _onClear() {
    setState(() {
      _selectedPickupType = PickupTypeFilter.all;
      _selectedCollectionStatus = CollectionStatusFilter.all;
    });
  }

  void _onApply() {
    final newFilter = ScheduleFilterModel(
      pickupType: _selectedPickupType,
      collectionStatus: _selectedCollectionStatus,
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
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title & Close Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: "Select pickup type."
                    const Text(
                      'Select pickup type.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFilterOption(
                      title: 'Select all',
                      icon: Icons.check_rounded,
                      isSelected: _selectedPickupType == PickupTypeFilter.all,
                      onTap: () {
                        setState(() {
                          _selectedPickupType = PickupTypeFilter.all;
                        });
                      },
                    ),
                    _buildFilterOption(
                      title: 'Sanitary pickups',
                      icon: Icons.assignment_outlined,
                      isSelected:
                          _selectedPickupType == PickupTypeFilter.sanitary,
                      onTap: () {
                        setState(() {
                          _selectedPickupType = PickupTypeFilter.sanitary;
                        });
                      },
                    ),
                    _buildFilterOption(
                      title: 'Scrap pickups',
                      icon: Icons.grid_view_rounded,
                      isSelected: _selectedPickupType == PickupTypeFilter.scrap,
                      onTap: () {
                        setState(() {
                          _selectedPickupType = PickupTypeFilter.scrap;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Section 2: "Filter by collection status"
                    const Text(
                      'Filter by collection status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFilterOption(
                      title: 'Select all',
                      icon: Icons.check_rounded,
                      isSelected: _selectedCollectionStatus ==
                          CollectionStatusFilter.all,
                      onTap: () {
                        setState(() {
                          _selectedCollectionStatus =
                              CollectionStatusFilter.all;
                        });
                      },
                    ),
                    _buildFilterOption(
                      title: 'Only pending pickups',
                      icon: Icons.hourglass_empty_rounded,
                      isSelected: _selectedCollectionStatus ==
                          CollectionStatusFilter.pending,
                      onTap: () {
                        setState(() {
                          _selectedCollectionStatus =
                              CollectionStatusFilter.pending;
                        });
                      },
                    ),
                    _buildFilterOption(
                      title: 'Only completed pickups',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: _selectedCollectionStatus ==
                          CollectionStatusFilter.completed,
                      onTap: () {
                        setState(() {
                          _selectedCollectionStatus =
                              CollectionStatusFilter.completed;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Buttons: Clear & Apply
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _onClear,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildFilterOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAF5F2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildRadioButton(isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButton(bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1E293B)
              : const Color(0xFFCBD5E1),
          width: 2.0,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
