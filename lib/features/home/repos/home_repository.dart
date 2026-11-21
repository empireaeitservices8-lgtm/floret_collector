import 'package:floret_collector/features/home/model/bag_assignment_model.dart';
import 'package:floret_collector/features/home/model/bag_model.dart';
import 'package:floret_collector/features/home/model/collector_route_pickups_model.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:flutter/foundation.dart';

abstract class HomeRepository {
  Future<List<BagModel>> getBags();
  Future<BagModel> getBagDetails(int id);
  Future<BagAssignmentModel?> getBagAssignment(String collectorId);
  Future<List<LocationPickupModel>> getLocations();
  Future<CollectorRoutePickupsResponse?> getMyAssignedRoutes(
      String collectorName);
  Future<CollectorRoutePickupsResponse?> getCollectorPickupsByRoute(
      String collectorName);
}

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient apiClient;

  HomeRepositoryImpl(this.apiClient);

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

  @override
  Future<CollectorRoutePickupsResponse?> getMyAssignedRoutes(
      String collectorName) async {
    try {
      final name =
          collectorName.trim().isNotEmpty ? collectorName.trim() : 'sanu';
      final response = await apiClient.get(
        APIEndPoints.myAssignedRoutes,
        queryParameters: {'collector_name': name},
      );
      debugPrint(
          'GET ${APIEndPoints.myAssignedRoutes}?collector_name=$name response: ${response.statusCode}');
      if (response.data is Map) {
        return CollectorRoutePickupsResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching my assigned routes: $e');
      return null;
    }
  }

  @override
  Future<CollectorRoutePickupsResponse?> getCollectorPickupsByRoute(
      String collectorName) =>
      getMyAssignedRoutes(collectorName);
}
