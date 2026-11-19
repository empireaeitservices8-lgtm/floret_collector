import 'dart:io';
import 'package:dio/dio.dart';
import 'package:floret_collector/features/direct_disposal/model/direct_disposal_model.dart';
import 'package:floret_collector/features/direct_disposal/repos/direct_disposal_repository.dart';
import 'package:floret_collector/features/direct_disposal/screen/widgets/date_filter.dart';
import 'package:floret_collector/features/direct_disposal/viewmodel/direct_disposal_view_model.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildDisposalLogsList({
  required BuildContext context,
  required DirectDisposalViewModel vm,
  required TextEditingController searchController,
}) {
  final logs = vm.filteredLogs;
  final hasDateFilter = vm.selectedDateRange != null;

  return Column(
    children: [
      // Top Controls: Search Bar + Date Filter Button + Download Button
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(
          children: [
            // Search Input
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: vm.setSearchQuery,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Search by Customer Name, Phone, or Waste Type...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: vm.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            onPressed: () {
                              searchController.clear();
                              vm.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Date Filter Button
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color:
                        hasDateFilter ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasDateFilter
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Filter by Date',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PickupCalendar(
                          initialDateRange: vm.selectedDateRange,
                          onDateRangeSelected: (range) {
                            vm.setSelectedDateRange(range);
                          },
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.tune,
                      size: 22,
                      color: hasDateFilter
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (hasDateFilter)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),

            // Download Button
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: vm.isExporting
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Download Logs',
                      onPressed: () => _downloadLogsCsv(context, logs, vm: vm),
                      icon: const Icon(
                        Icons.file_download_outlined,
                        size: 22,
                        color: Color(0xFF0F172A),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // Active Date Range Filter Indicator Chip
      if (hasDateFilter)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(vm.selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(vm.selectedDateRange!.end)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => vm.setSelectedDateRange(null),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${logs.length} record${logs.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

      // Logs List
      Expanded(
        child: logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 54,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Disposal Logs Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (hasDateFilter) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => vm.setSelectedDateRange(null),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Clear Date Filter'),
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final item = logs[index];
                  return buildLogCard(context, item);
                },
              ),
      ),
    ],
  );
}

Widget buildLogCard(BuildContext context, DirectDisposalLogModel item) {
  final isPaid = item.isPaid;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _showLogDetailSheet(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Top Row: Avatar/Icon + Customer Name & Phone + Status Badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phone: ${item.phone}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isPaid
                          ? const Color(0xFF15803D)
                          : const Color(0xFF92400E),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
            const SizedBox(height: 12),

            // Middle Row: 4 Columns (Waste Type | Weight | GST | Total Paid)
            Row(
              children: [
                // Waste Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waste Type',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.wasteType,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Weight
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                // GST
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GST (${item.gstRatePercent.toInt()}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.gstAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Paid
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Paid',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
            const SizedBox(height: 10),

            // Bottom Row: Date + Method + Tap for details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.paymentMethod.toUpperCase() == 'ONLINE'
                          ? Icons.credit_card_outlined
                          : Icons.money_outlined,
                      size: 16,
                      color: const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.paymentMethod.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Full Details Modal Bottom Sheet
void _showLogDetailSheet(BuildContext context, DirectDisposalLogModel item) {
  final isPaid = item.isPaid;
  final subtotal = item.weight * item.rate;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Title Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Disposal Log Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            item.formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isPaid
                              ? const Color(0xFF15803D)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFF1F5F9), height: 1),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Card
                    _buildSectionHeader('Customer Information'),
                    _buildDetailCard([
                      _buildDetailRow('Name', item.customerName),
                      _buildDetailRow('Phone', item.phone, isPhone: true),
                      _buildDetailRow('Address', item.customerAddress),
                    ]),

                    const SizedBox(height: 16),

                    // Waste Parameters Card
                    _buildSectionHeader('Waste Parameters'),
                    _buildDetailCard([
                      _buildDetailRow('Disposal Type', item.disposalType),
                      _buildDetailRow('Waste Type', item.wasteType),
                      if (item.bagCount > 0)
                        _buildDetailRow('Waste Bags', '${item.bagCount} bags'),
                      _buildDetailRow(
                        'Description',
                        item.wasteDescription.isEmpty
                            ? '—'
                            : item.wasteDescription,
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Financial Breakdown Card
                    _buildSectionHeader('Financial & Billing Details'),
                    _buildDetailCard([
                      _buildDetailRow(
                          'Weight', '${item.weight.toStringAsFixed(2)} kg'),
                      _buildDetailRow('Disposal Rate',
                          '₹${item.rate.toStringAsFixed(2)}/kg'),
                      _buildDetailRow(
                          'Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                      _buildDetailRow(
                        'GST (${item.gstRatePercent.toInt()}%)',
                        '₹${item.gstAmount.toStringAsFixed(2)}',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Divider(
                            color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                      ),
                      _buildDetailRow(
                        'Total Amount',
                        '₹${item.totalAmount.toStringAsFixed(2)}',
                        isHighlighted: true,
                      ),
                      _buildDetailRow('Payment Mode', item.paymentMethod),
                    ]),

                    if (item.recordedBy != null &&
                        item.recordedBy!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionHeader('Collection Officer'),
                      _buildDetailCard([
                        _buildDetailRow('Recorded By', item.recordedBy!),
                      ]),
                    ],

                    const SizedBox(height: 20),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.2,
      ),
    ),
  );
}

Widget _buildDetailCard(List<Widget> children) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: children,
    ),
  );
}

Widget _buildDetailRow(
  String label,
  String value, {
  bool isHighlighted = false,
  bool isPhone = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: isHighlighted
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 13,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              color: isHighlighted
                  ? const Color(0xFF15803D)
                  : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    ),
  );
}

// Download / Export Logs Feature
Future<void> _downloadLogsCsv(
  BuildContext context,
  List<DirectDisposalLogModel> logs, {
  DirectDisposalViewModel? vm,
}) async {
  if (logs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No disposal logs available to download'),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
    return;
  }

  try {
    // Determine target directory
    Directory? targetDir;
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          try {
            final testFile = File(
              '${downloadDir.path}/.perm_check_${DateTime.now().millisecondsSinceEpoch}',
            );
            await testFile.writeAsString('ok');
            await testFile.delete();
            targetDir = downloadDir;
          } catch (_) {
            targetDir = await getExternalStorageDirectory();
          }
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      }
    } catch (_) {}
    targetDir ??= await getApplicationDocumentsDirectory();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String finalFileName = 'direct_disposal_logs_$timestamp.xml';
    String finalPath = '${targetDir.path}/$finalFileName';

    // 1. Use dio.download method (API returns XML)
    bool downloadedFromApi = false;
    Response? res;
    if (vm != null) {
      res = await vm.downloadLogs(finalPath);
      if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
        downloadedFromApi = true;
      }
    } else {
      try {
        res = await DirectDisposalRepository().downloadDisposalLogs(finalPath);
        if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
          downloadedFromApi = true;
        }
      } catch (_) {}
    }

    if (downloadedFromApi && res != null) {
      // Check if server specified a filename in Content-Disposition header
      try {
        final disposition = res.headers.value('content-disposition');
        if (disposition != null && disposition.contains('filename=')) {
          final match = RegExp(
            r'filename=["\x27]?([^"\x27;]+)["\x27]?',
          ).firstMatch(disposition);
          if (match != null && match.group(1) != null) {
            final serverFileName = match.group(1)!.trim();
            if (serverFileName.isNotEmpty) {
              final newPath = '${targetDir.path}/$serverFileName';
              final downloadedFile = File(finalPath);
              if (await downloadedFile.exists()) {
                await downloadedFile.rename(newPath);
                finalPath = newPath;
                finalFileName = serverFileName;
              }
            }
          }
        }
      } catch (_) {}
    }

    // Fallback: Generate CSV content from current logs if API download failed or wasn't available
    if (!downloadedFromApi) {
      final csvFileName = 'direct_disposal_logs_$timestamp.csv';
      final csvPath = '${targetDir.path}/$csvFileName';
      final buffer = StringBuffer();
      buffer.writeln(
        'ID,Customer Name,Phone,Address,Disposal Type,Waste Type,Description,Weight (kg),Rate (INR),Subtotal (INR),GST (%),GST Amount (INR),Total Amount (INR),Payment Method,Payment Status,Date,Recorded By',
      );

      for (final item in logs) {
        final subtotal = item.weight * item.rate;
        final row = [
          _escapeCsv(item.id),
          _escapeCsv(item.customerName),
          _escapeCsv(item.phone),
          _escapeCsv(item.customerAddress),
          _escapeCsv(item.disposalType),
          _escapeCsv(item.wasteType),
          _escapeCsv(item.wasteDescription),
          item.weight.toStringAsFixed(2),
          item.rate.toStringAsFixed(2),
          subtotal.toStringAsFixed(2),
          item.gstRatePercent.toStringAsFixed(1),
          item.gstAmount.toStringAsFixed(2),
          item.totalAmount.toStringAsFixed(2),
          _escapeCsv(item.paymentMethod),
          _escapeCsv(item.paymentStatus),
          _escapeCsv(item.formattedDate),
          _escapeCsv(item.recordedBy ?? ''),
        ];
        buffer.writeln(row.join(','));
      }

      final file = File(csvPath);
      await file.writeAsString(buffer.toString());
      finalPath = csvPath;
      finalFileName = csvFileName;
    }

    // Function to open the downloaded file with OpenFilex
    Future<void> openFile() async {
      try {
        final result = await OpenFilex.open(finalPath);
        debugPrint('OpenFilex result: ${result.type} - ${result.message}');
        if (result.type != ResultType.done) {
          final uri = Uri.file(finalPath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        debugPrint('Could not open file with OpenFilex: $e');
        try {
          final uri = Uri.file(finalPath);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }

    // Automatically open the downloaded file immediately
    await openFile();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logs exported successfully! 📄',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              'Saved: $finalFileName',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        action: SnackBarAction(
          label: 'OPEN',
          textColor: const Color(0xFF60A5FA),
          onPressed: openFile,
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to download logs: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }
}

String _escapeCsv(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
