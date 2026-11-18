import 'location_pickup_model.dart';

class AssignedRouteModel {
  final String district;
  final String localBody;
  final String ward;

  const AssignedRouteModel({
    required this.district,
    required this.localBody,
    required this.ward,
  });

  factory AssignedRouteModel.fromJson(Map<String, dynamic> json) {
    return AssignedRouteModel(
      district: json['district']?.toString() ?? '',
      localBody: json['local_body']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'district': district,
        'local_body': localBody,
        'ward': ward,
      };

  @override
  String toString() =>
      'AssignedRouteModel(district: $district, localBody: $localBody, ward: $ward)';
}

class CollectorRoutePickupsResponse {
  final String collectorName;
  final List<AssignedRouteModel> assignedRoutes;
  final List<LocationPickupModel> pickups;
  final int totalPickups;

  const CollectorRoutePickupsResponse({
    required this.collectorName,
    required this.assignedRoutes,
    required this.pickups,
    required this.totalPickups,
  });

  factory CollectorRoutePickupsResponse.fromJson(Map<String, dynamic> json) {
    final routesRaw = json['assigned_routes'];
    final routes = <AssignedRouteModel>[];
    if (routesRaw is List) {
      for (final item in routesRaw) {
        if (item is Map) {
          routes.add(
            AssignedRouteModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final pickupsRaw = json['pickups'];
    final pickupsList = <LocationPickupModel>[];
    if (pickupsRaw is List) {
      for (final item in pickupsRaw) {
        if (item is Map) {
          pickupsList.add(
            LocationPickupModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return CollectorRoutePickupsResponse(
      collectorName: json['collector_name']?.toString() ?? '',
      assignedRoutes: routes,
      pickups: pickupsList,
      totalPickups:
          (json['total_pickups'] as num?)?.toInt() ?? pickupsList.length,
    );
  }

  @override
  String toString() =>
      'CollectorRoutePickupsResponse(collector: $collectorName, total: $totalPickups, routes: ${assignedRoutes.length}, pickups: ${pickups.length})';
}
