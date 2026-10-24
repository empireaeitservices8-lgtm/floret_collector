import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:floret_collector/features/collection_route/repository/ward_route_repository.dart';

class MarkCompletedWithWarningScreen extends StatefulWidget {
  static const String routeName = '/MarkCompletedWithWarningScreen';

  final int pickupId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String placeName;
  final String address;

  const MarkCompletedWithWarningScreen({
    super.key,
    required this.pickupId,
    required this.userName,
    this.userEmail = '',
    required this.userPhone,
    required this.placeName,
    required this.address,
  });

  @override
  State<MarkCompletedWithWarningScreen> createState() =>
      _MarkCompletedWithWarningScreenState();
}

class _MarkCompletedWithWarningScreenState
    extends State<MarkCompletedWithWarningScreen> {
  final _repository = WardRouteRepository();
  final _otherReasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedReason;
  File? _selectedMedia;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Improper bags',
    'Mixed waste',
    'High rate',
    'Collected by other agency',
    'Dispose by themselves',
    'Other',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Other') {
      if (_otherReasonController.text.trim().isEmpty) return false;
      if (_descriptionController.text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked =
                    await _imagePicker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _selectedMedia = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked =
                    await _imagePicker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _selectedMedia = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final subject = _selectedReason == 'Other'
        ? _otherReasonController.text.trim()
        : _selectedReason!;

    final commentText = _descriptionController.text.trim();
    final description = commentText.isNotEmpty
        ? commentText
        : 'Collector marked warning with reason: $subject.';

    final effectiveUserName = widget.userName.trim().isNotEmpty
        ? widget.userName.trim()
        : (widget.placeName.trim().isNotEmpty
            ? widget.placeName.trim()
            : 'User');

    try {
      final res = await _repository.reportIssue(
        userName: effectiveUserName,
        userEmail: widget.userEmail,
        userPhone: widget.userPhone,
        pickupId: widget.pickupId,
        issueType: 'collection',
        subject: subject,
        description: description,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res != null) {
        _showSuccessSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to report issue. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Alert icon circle badge
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 34,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Issue reported!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),

              // Info box (Place name & Address)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Place name',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.placeName.isNotEmpty
                                ? widget.placeName
                                : 'Main Road',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.address.isNotEmpty
                                ? widget.address
                                : 'Main Road',
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ok button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ok',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _selectedReason == 'Other';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF0F172A),
              size: 22,
            ),
          ),
        ),
        title: const Text(
          'Mark as completed with warning',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Reason for warning
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Reason for warning ',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: '(Required)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please select a reason for the warning.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reasons options
                    ..._reasons.map((reason) {
                      final isSelected = _selectedReason == reason;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedReason = reason;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF0FDF9)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.6 : 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Radio circle
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFCBD5E1),
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0F172A),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    reason,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // If "Other" selected, show "Specify Other Reason"
                          if (reason == 'Other' && isSelected) ...[
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Specify Other Reason ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '(Required)',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _otherReasonController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Enter specific reason...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14.5,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F172A),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    }),

                    const SizedBox(height: 8),

                    // Section 2: Add photo / video
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Add photo / video ',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: '(optional)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add a photo/ video to document the issue.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Media button or preview
                    if (_selectedMedia != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _selectedMedia!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedMedia = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _pickMedia,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 105,
                          height: 105,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 28,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Add Media',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Section 3: Comments / Description
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Comments / Description ',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          TextSpan(
                            text: isOther ? '(Required)' : '(optional)',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14.5,
                      ),
                      onChanged: (_) => setState(() {}),
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: isOther
                            ? 'Please enter the reason (mandatory)...'
                            : 'Enter warning or issue details...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14.5,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isFormValid && !_isSubmitting ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _isFormValid
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
