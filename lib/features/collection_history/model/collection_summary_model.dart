import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionSummaryModel {
  final int totalStops;
  final double totalWeight;
  final double totalAmount;

  const CollectionSummaryModel({
    this.totalStops = 0,
    this.totalWeight = 0.0,
    this.totalAmount = 0.0,
  });

  // Keeps compatibility with your existing UI.
  int get totalPickups => totalStops;

  String get formattedWeight {
    if (totalWeight == totalWeight.roundToDouble()) {
      return '${totalWeight.toInt()} kg';
    }

    return '${totalWeight.toStringAsFixed(2)} kg';
  }

  String get formattedAmount {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: totalAmount == totalAmount.roundToDouble() ? 0 : 2,
    ).format(totalAmount);
  }

  factory CollectionSummaryModel.fromJson(Map<String, dynamic> json) {
    return CollectionSummaryModel(
      totalStops: _asInt(json['total_collections']),
      totalWeight: _asDouble(json['total_weight_collected']),
      totalAmount: _asDouble(json['total_earnings']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
  }
}

class CollectionFilterModel {
  final DateTimeRange? dateRange;
  final String wasteType;
  final String paymentStatus;

  // Retained for existing UI; not sent to this API.
  final String paymentMethod;

  const CollectionFilterModel({
    this.dateRange,
    this.wasteType = 'All',
    this.paymentStatus = 'All',
    this.paymentMethod = 'All',
  });

  int get activeFilterCount {
    int count = 0;

    if (dateRange != null) count++;
    if (_isSelected(wasteType)) count++;
    if (_isSelected(paymentStatus)) count++;
    if (_isSelected(paymentMethod)) count++;

    return count;
  }

  bool get hasFilters => activeFilterCount > 0;

  CollectionFilterModel copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? wasteType,
    String? paymentStatus,
    String? paymentMethod,
  }) {
    return CollectionFilterModel(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      wasteType: wasteType ?? this.wasteType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  /// Parses the API's `filters_applied` object.
  factory CollectionFilterModel.fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse(
      json['date_from']?.toString() ?? '',
    );
    final end = DateTime.tryParse(
      json['date_to']?.toString() ?? '',
    );

    return CollectionFilterModel(
      dateRange: start != null && end != null && !end.isBefore(start)
          ? DateTimeRange(start: start, end: end)
          : null,
      wasteType: _filterValue(json['waste_type']),
      paymentStatus: _formatStatus(json['payment_status']),
    );
  }

  /// Builds query parameters for the history GET request.
  Map<String, dynamic> toQueryParameters() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return {
      if (dateRange != null) 'date_from': dateFormat.format(dateRange!.start),
      if (dateRange != null) 'date_to': dateFormat.format(dateRange!.end),
      if (_isSelected(wasteType)) 'waste_type': wasteType.trim(),
      if (_isSelected(paymentStatus))
        'payment_status': paymentStatus.trim().toLowerCase(),
    };
  }

  static bool _isSelected(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'all';
  }

  static String _filterValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return _isSelected(text) ? text : 'All';
  }

  static String _formatStatus(dynamic value) {
    final text = _filterValue(value).toLowerCase();
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  static const CollectionFilterModel empty = CollectionFilterModel();
}
