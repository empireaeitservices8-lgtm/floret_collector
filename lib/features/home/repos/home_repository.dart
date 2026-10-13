import 'package:floret_collector/features/home/model/bag_assignment_model.dart';
import 'package:floret_collector/features/home/model/bag_model.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import 'package:floret_collector/features/home/model/pickup_slot_model.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:flutter/foundation.dart';

abstract class HomeRepository {
  Future<PickupSlotsResponseModel> getPickupSlots();
  Future<List<BagModel>> getBags();
  Future<BagModel> getBagDetails(int id);
  Future<BagAssignmentModel?> getBagAssignment(String collectorId);
  Future<List<LocationPickupModel>> getLocations();
}

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient apiClient;

  HomeRepositoryImpl(this.apiClient);

  @override
  Future<PickupSlotsResponseModel> getPickupSlots() async {
    final response = await apiClient.get(
      APIEndPoints.pickupSlots,
    );
    debugPrint('called ${APIEndPoints.pickupSlots}');
    return PickupSlotsResponseModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  //bags
  @override
  Future<List<BagModel>> getBags() async {
    final response = await apiClient.get(
      APIEndPoints.bags,
    );
    debugPrint('called ${APIEndPoints.bags}');
    final List<dynamic> data = response.data as List<dynamic>;

    return data
        .map((item) => BagModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  @override
  Future<BagModel> getBagDetails(int id) async {
    final response = await apiClient.get(
      APIEndPoints.bagDetails(id),
    );
    return BagModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<BagAssignmentModel?> getBagAssignment(String collectorId) async {
    try {
      final response = await apiClient.get(
        APIEndPoints.bagAssignment,
        queryParameters: {'collector_id': collectorId},
      );
      debugPrint('GET bag assignment from ${APIEndPoints.bagAssignment}');
      debugPrint('Fetch Bag Assignment Status: ${response.statusCode}, Body: ${response.data}');
      if (response.data is Map) {
        return BagAssignmentModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching bag assignment: $e');
      return null;
    }
  }

  @override
  Future<List<LocationPickupModel>> getLocations() async {
    try {
      final response = await apiClient.get(APIEndPoints.locations);
      debugPrint('GET locations from ${APIEndPoints.locations}');
      debugPrint('Fetch Locations Response Status: ${response.statusCode}');
      if (response.data is List) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((item) => LocationPickupModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }
}
