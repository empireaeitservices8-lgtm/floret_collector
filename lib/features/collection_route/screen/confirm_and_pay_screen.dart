import 'package:flutter/material.dart';
import 'package:floret_collector/features/collection_route/viewModel/confirm_and_pay_view_model.dart';
import 'payment_receipt_screen.dart';
import 'razorpay_qr_screen.dart';

class ConfirmAndPayScreen extends StatefulWidget {
  static const String routeName = '/ConfirmAndPayScreen';

  final int pickupId;
  final int collectorId;
  final String address;
  final String wasteType;
  final String localBody;
  final double? disposalRate;

  const ConfirmAndPayScreen({
    super.key,
    this.pickupId = 0,
    this.collectorId = 0,
    this.address = '',
    this.wasteType = '',
    this.localBody = '',
    this.disposalRate,
  });

  @override
  State<ConfirmAndPayScreen> createState() => _ConfirmAndPayScreenState();
}

class _ConfirmAndPayScreenState extends State<ConfirmAndPayScreen> {
  late final ConfirmAndPayViewModel _viewModel;
  final TextEditingController _weightController =
      TextEditingController(text: '5.0');

  @override
  void initState() {
    super.initState();
    _viewModel = ConfirmAndPayViewModel(
      pickupId: widget.pickupId,
      collectorId: widget.collectorId,
      initialAddress: widget.address,
      initialWasteType: widget.wasteType,
      initialLocalBody: widget.localBody,
      initialDisposalRate: widget.disposalRate,
    );

    _weightController.addListener(_onWeightChanged);
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadInitialData();
  }

  void _onWeightChanged() {
    _viewModel.setWasteWeightFromString(_weightController.text);
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _viewModel.removeListener(_onViewModelChanged);
    _weightController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmPayment() async {
    final success = await _viewModel.confirmPayment();
    if (!mounted) return;

    if (success) {
      final navResult = await Navigator.pushNamed(
        context,
        PaymentReceiptScreen.routeName,
        arguments: _viewModel.paymentReceiptArguments,
      );

      if (navResult == true && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _handleGenerateRazorpayQR() async {
    await _viewModel.ensureBillGenerated();
    if (!mounted) return;

    final result = await Navigator.pushNamed(
      context,
      RazorpayQRScreen.routeName,
      arguments: _viewModel.razorpayQRArguments,
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handlePickVerificationPhoto() async {
    if (_viewModel.hasMaxPhotos) {
      _showSnack('Maximum 5 verification photos allowed', isError: true);
      return;
    }

    try {
      await _viewModel.pickVerificationPhoto();
    } catch (e) {
      if (mounted) {
        _showSnack('Could not open camera: $e', isError: true);
      }
    }
  }

  Future<void> _handleUploadPhoto(int index) async {
    final success = await _viewModel.uploadPhoto(index);
    if (!mounted) return;

    if (_viewModel.lastUploadMessage != null) {
      _showSnack(_viewModel.lastUploadMessage!, isError: !success);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.isFetchingInitialData || _viewModel.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Confirm & Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E293B),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm & Pay',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Address Card
            _buildAddressCard(),
            const SizedBox(height: 18),

            // Section 1: Choose Waste Bag Quantity
            _buildSectionHeader('1. Choose Waste Bag Quantity'),
            const SizedBox(height: 8),
            _buildBagQuantityCard(),
            const SizedBox(height: 18),

            // Section 2: Localbody Disposal Location & Weight
            _buildSectionHeader('2. Localbody Disposal Location & Weight'),
            const SizedBox(height: 8),
            _buildLocalbodyCard(),
            const SizedBox(height: 10),
            _buildWasteWeightInputCard(),
            const SizedBox(height: 20),

            // Section 3: Payment Option
            _buildSectionHeader('3. Payment Option'),
            const SizedBox(height: 8),
            _buildPaymentOptions(),
            if (_viewModel.isOnlinePayment) ...[
              _buildRazorpayQRPreviewCard(),
            ],
            const SizedBox(height: 18),

            // Section 4: Weighing Machine Verification Photo
            _buildSectionHeader('4. Weighing Machine Verification Photo'),
            const SizedBox(height: 8),
            _buildPhotoVerificationSection(),
            const SizedBox(height: 18),

            // Collection Summary
            _buildCollectionSummaryCard(),
            const SizedBox(height: 20),

            // Confirm Payment / Generate QR Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _viewModel.isOnlinePayment
                    ? _handleGenerateRazorpayQR
                    : _handleConfirmPayment,
                icon: Icon(
                  _viewModel.isOnlinePayment
                      ? Icons.qr_code_2_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  _viewModel.confirmButtonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _viewModel.isOnlinePayment
                      ? const Color(0xFF0F1E36)
                      : const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _viewModel.addressDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _viewModel.userSubtitleDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagQuantityCard() {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Waste Bag',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _viewModel.bagPriceLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _viewModel.bagQuantity > 0
                    ? _viewModel.decrementBagQuantity
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 24),
                color: const Color(0xFF1E293B),
                disabledColor: const Color(0xFFCBD5E1),
              ),
              Text(
                '${_viewModel.bagQuantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: _viewModel.incrementBagQuantity,
                icon: const Icon(Icons.add_circle_outline, size: 24),
                color: const Color(0xFF1E293B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalbodyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Assigned Localbody',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              _viewModel.localBodySummaryLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteWeightInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waste Weight (Kgs)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.scale_outlined,
                size: 20,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(
                width: 2,
              ),
              const Text(
                'Kg',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    final options = [
      {'title': 'Cash', 'icon': Icons.payments_outlined},
      {'title': 'Online (QR)', 'icon': Icons.qr_code_2_rounded},
    ];

    return Row(
      children: options.map((opt) {
        final title = opt['title'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _viewModel.selectedPaymentOption == title;

        return Expanded(
          child: GestureDetector(
            onTap: () => _viewModel.setSelectedPaymentOption(title),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRazorpayQRPreviewCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1E36),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Razorpay Dynamic QR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F1E36),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded,
                        size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'SECURE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _viewModel.qrPreviewText,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleGenerateRazorpayQR,
              icon: const Icon(Icons.qr_code_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Generate Razorpay QR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1E36),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItemCard(int index, VerificationPhotoItem photo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              photo.file,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: const Color(0xFFF1F5F9),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  photo.statusText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: photo.statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons: Upload & Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!photo.isUploaded)
                InkWell(
                  onTap: photo.isUploading
                      ? null
                      : () => _handleUploadPhoto(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: photo.isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Upload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _viewModel.deletePhoto(index),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: _handlePickVerificationPhoto,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 22,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _viewModel.photoCountLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Capture weighing machine display showing weight',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoVerificationSection() {
    final photos = _viewModel.verificationPhotos;
    return Column(
      children: [
        for (int i = 0; i < photos.length; i++)
          _buildPhotoItemCard(i, photos[i]),
        if (_viewModel.canAddMorePhotos) _buildAddPhotoCard(),
      ],
    );
  }

  Widget _buildCollectionSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            _viewModel.bagsCostSummaryLabel,
            _viewModel.formattedBagsCost,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            _viewModel.disposalFeeSummaryLabel,
            _viewModel.formattedDisposalFee,
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          _buildSummaryRow('Subtotal', _viewModel.formattedSubtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('GST (18%)', _viewModel.formattedGst),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Gross Total (incl. GST)',
            _viewModel.formattedGrossTotal,
            isBold: true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount Payable',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _viewModel.formattedTotalPayable,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
