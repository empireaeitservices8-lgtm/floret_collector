import 'package:flutter/material.dart';

class CollectionItemModel {
  final String id;
  final String stopId;
  final String stopName;
  final String wasteType;
  final String status; // 'Paid' or 'Pending'
  final double weight;
  final double rate;
  final double amount;
  final String date;
  final DateTime? dateTime;
  final String paymentMethod; // 'Cash' or 'Online'

  const CollectionItemModel({
    required this.id,
    required this.stopId,
    required this.stopName,
    required this.wasteType,
    required this.status,
    required this.weight,
    required this.rate,
    required this.amount,
    required this.date,
    this.dateTime,
    required this.paymentMethod,
  });

  factory CollectionItemModel.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weight'] ?? json['weight_collected'] ?? 0.0;
    final rawRate = json['rate'] ?? json['rate_per_kg'] ?? 0.0;
    final rawAmount = json['amount'] ?? json['total_amount'] ?? 0.0;

    return CollectionItemModel(
      id: json['id']?.toString() ?? '',
      stopId: json['stop_id']?.toString() ??
          json['stopId']?.toString() ??
          json['pickup_id']?.toString() ??
          json['stop']?.toString() ??
          '',
      stopName: json['stop_name']?.toString() ??
          json['stopName']?.toString() ??
          json['user_name']?.toString() ??
          json['customer_name']?.toString() ??
          '',
      wasteType: json['waste_type']?.toString() ??
          json['wasteType']?.toString() ??
          'General Waste',
      status: json['payment_status']?.toString() ??
          json['status']?.toString() ??
          'Paid',
      weight: rawWeight is num ? rawWeight.toDouble() : (double.tryParse(rawWeight.toString()) ?? 0.0),
      rate: rawRate is num ? rawRate.toDouble() : (double.tryParse(rawRate.toString()) ?? 0.0),
      amount: rawAmount is num ? rawAmount.toDouble() : (double.tryParse(rawAmount.toString()) ?? 0.0),
      date: json['date']?.toString() ??
          json['collection_date']?.toString() ??
          json['created_at']?.toString() ??
          '',
      paymentMethod: json['payment_method']?.toString() ??
          json['method']?.toString() ??
          'Cash',
    );
  }
}

class CollectionSummaryModel {
  final int totalStops;
  final double totalWeight;
  final double totalAmount;

  const CollectionSummaryModel({
    this.totalStops = 0,
    this.totalWeight = 0.0,
    this.totalAmount = 0.0,
  });

  factory CollectionSummaryModel.fromJson(Map<String, dynamic> json) {
    final totalStops = json['total_collections'] ?? json['total_stops'] ?? 0;
    final rawWeight = json['total_weight_collected'] ?? json['total_weight'] ?? '0';
    final rawAmount = json['total_earnings'] ?? json['total_amount'] ?? '0';

    return CollectionSummaryModel(
      totalStops: totalStops is int ? totalStops : (int.tryParse(totalStops.toString()) ?? 0),
      totalWeight: rawWeight is num
          ? rawWeight.toDouble()
          : (double.tryParse(rawWeight.toString()) ?? 0.0),
      totalAmount: rawAmount is num
          ? rawAmount.toDouble()
          : (double.tryParse(rawAmount.toString()) ?? 0.0),
    );
  }
}

class CollectionFilterModel {
  final DateTimeRange? dateRange;
  final String wasteType; // 'All', 'Household', 'Sanitary Waste', 'Mixed waste', etc.
  final String paymentStatus; // 'All', 'Paid', 'Pending'
  final String paymentMethod; // 'All', 'Cash', 'Online'

  const CollectionFilterModel({
    this.dateRange,
    this.wasteType = 'All',
    this.paymentStatus = 'All',
    this.paymentMethod = 'All',
  });

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if (wasteType != 'All') count++;
    if (paymentStatus != 'All') count++;
    if (paymentMethod != 'All') count++;
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

  static const CollectionFilterModel empty = CollectionFilterModel();
}
