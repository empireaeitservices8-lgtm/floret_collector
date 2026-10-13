import 'package:flutter/material.dart';
import '../viewmodel/menu_view_model.dart';

class VehicleAssignmentBottomSheet extends StatefulWidget {
  final MenuViewModel viewModel;

  const VehicleAssignmentBottomSheet({
    super.key,
    required this.viewModel,
  });

  static Future<void> show({
    required BuildContext context,
    required MenuViewModel viewModel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VehicleAssignmentBottomSheet(viewModel: viewModel),
    );
  }

  @override
  State<VehicleAssignmentBottomSheet> createState() =>
      _VehicleAssignmentBottomSheetState();
}

class _VehicleAssignmentBottomSheetState
    extends State<VehicleAssignmentBottomSheet> {
  late final TextEditingController _collectorIdController;
  late final TextEditingController _vehicleNameController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _aadhaarPhotoController;

  bool _isFetching = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.viewModel.profile;
    _collectorIdController =
        TextEditingController(text: profile.collectorId);
    _vehicleNameController =
        TextEditingController(text: profile.vehicleName);
    _vehicleNumberController =
        TextEditingController(text: profile.regNo);
    _aadhaarPhotoController =
        TextEditingController(text: profile.aadhaarPhoto);

    // If aadhaar photo or fields are empty, auto-fetch GET in background
    if (_aadhaarPhotoController.text.isEmpty) {
      _fetchVehicleDetails(silent: true);
    }
  }

  @override
  void dispose() {
    _collectorIdController.dispose();
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _aadhaarPhotoController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicleDetails({bool silent = false}) async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    final collectorId = _collectorIdController.text.trim();
    final result = await widget.viewModel.fetchVehicleAssignment(
      collectorId: collectorId.isNotEmpty ? collectorId : null,
    );

    if (mounted) {
      setState(() {
        _isFetching = false;
        if (result != null) {
          if (result['vehicle_name'] != null) {
            _vehicleNameController.text = result['vehicle_name'].toString();
          }
          if (result['vehicle_number'] != null) {
            _vehicleNumberController.text = result['vehicle_number'].toString();
          }
          if (result['aadhaar_card_photo'] != null) {
            _aadhaarPhotoController.text =
                result['aadhaar_card_photo'].toString();
          }
          if (result['collector_id'] != null) {
            _collectorIdController.text = result['collector_id'].toString();
          }
        }
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null
                  ? 'Vehicle details fetched successfully'
                  : 'Failed to fetch vehicle details',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _assignVehicle() async {
    if (_isAssigning) return;
    final collectorId = _collectorIdController.text.trim();
    final vehicleName = _vehicleNameController.text.trim();
    final vehicleNumber = _vehicleNumberController.text.trim();
    final aadhaarPhoto = _aadhaarPhotoController.text.trim();

    if (collectorId.isEmpty || vehicleName.isEmpty || vehicleNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    final result = await widget.viewModel.assignVehicle(
      collectorId: collectorId,
      vehicleName: vehicleName,
      vehicleNumber: vehicleNumber,
      aadhaarPhoto: aadhaarPhoto.isNotEmpty ? aadhaarPhoto : null,
    );

    if (mounted) {
      setState(() => _isAssigning = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vehicle assigned successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to assign vehicle',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_ind_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Assignment (Admin)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'POST /api/admin/assign-vehicle/',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Fields
          _buildField(
            label: 'COLLECTOR ID',
            icon: Icons.badge_outlined,
            controller: _collectorIdController,
          ),
          const SizedBox(height: 14),

          _buildField(
            label: 'VEHICLE NAME',
            icon: Icons.directions_car_outlined,
            controller: _vehicleNameController,
          ),
          const SizedBox(height: 14),

          _buildField(
            label: 'VEHICLE REGISTRATION NUMBER',
            icon: Icons.pin_outlined,
            controller: _vehicleNumberController,
          ),
          const SizedBox(height: 14),

          _buildField(
            label: 'AADHAAR CARD PHOTO URL',
            icon: Icons.image_outlined,
            controller: _aadhaarPhotoController,
          ),

          const SizedBox(height: 24),

          // Action Buttons Row
          Row(
            children: [
              // Fetch GET Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isFetching ? null : () => _fetchVehicleDetails(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4338CA),
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isFetching)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4338CA),
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.sync_rounded,
                            size: 18,
                            color: Color(0xFF4338CA),
                          ),
                        const SizedBox(width: 8),
                        const Text(
                          'Fetch GET',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Assign POST Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isAssigning ? null : _assignVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isAssigning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        const Text(
                          'Assign POST',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
}
