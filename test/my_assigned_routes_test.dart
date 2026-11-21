import 'package:flutter_test/flutter_test.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:floret_collector/features/home/model/collector_route_pickups_model.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';

void main() {
  group('My Assigned Routes API and Models Tests', () {
    test('APIEndPoints contains myAssignedRoutes endpoint', () {
      expect(APIEndPoints.myAssignedRoutes, '/api/my-assigned-routes/');
      expect(APIEndPoints.getMyAssignedRoutes('nabeel'),
          '/api/my-assigned-routes/?collector_name=nabeel');
      expect(APIEndPoints.getMyAssignedRoutes('sanu kumar'),
          '/api/my-assigned-routes/?collector_name=sanu%20kumar');
    });

    test('CollectorRoutePickupsResponse parses sample user response correctly',
        () {
      final sampleJson = {
        "collector_id": null,
        "collector_name": "nabeel",
        "assigned_routes": [
          {
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": ", KALLUVARAMBU, IRINCHIYAM, KUSARKODE"
          }
        ],
        "pickups": [
          {
            "id": 601,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "rescheduled",
            "street": "tvcra",
            "city": "csez",
            "landmark": "",
            "collector_name": "new",
            "created_at": "2026-11-18 05:16:40.088807+00:00"
          },
          {
            "id": 630,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "tvcra",
            "city": "csez",
            "landmark": "",
            "collector_name": "new",
            "created_at": "2026-11-20 06:15:41.431870+00:00"
          },
          {
            "id": 632,
            "user_id": 462,
            "user_name": "917306929058_386",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "sjdjmz",
            "city": "snnmd",
            "landmark": "",
            "collector_name": "new",
            "created_at": "2026-11-20 07:11:44.356111+00:00"
          },
          {
            "id": 635,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "abc",
            "city": "navy",
            "landmark": "",
            "collector_name": "Nabeel",
            "created_at": "2026-11-20 09:35:23.102399+00:00"
          },
          {
            "id": 636,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "2 - IRINCHIYAM",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "nhg",
            "city": "fy",
            "landmark": "",
            "collector_name": "Nabeel",
            "created_at": "2026-11-20 09:36:51.564946+00:00"
          },
          {
            "id": 637,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "3 - KUSARKODE",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "fgh",
            "city": "gyu",
            "landmark": "",
            "collector_name": "Nabeel",
            "created_at": "2026-11-20 09:38:24.151499+00:00"
          },
          {
            "id": 640,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "tvcra",
            "city": "csez",
            "landmark": "",
            "collector_name": null,
            "created_at": "2026-11-20 10:28:14.377656+00:00"
          },
          {
            "id": 641,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "1:00",
            "status": "pending",
            "street": "tvcra",
            "city": "csez",
            "landmark": "",
            "collector_name": null,
            "created_at": "2026-11-20 10:30:47.511956+00:00"
          },
          {
            "id": 642,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "9:00 AM – 12:00 PM",
            "status": "pending",
            "street": "tvcra",
            "city": "csez",
            "landmark": "",
            "collector_name": "Nabeel",
            "created_at": "2026-11-20 10:56:30.541152+00:00"
          },
          {
            "id": 645,
            "user_id": 465,
            "user_name": "919995723146_759",
            "district": "Thiruvananthapuram",
            "local_body": "Nedumangadu Municipality",
            "ward": "1 - KALLUVARAMBU",
            "pickup_date": "2026-11-20",
            "pickup_time_slot": "9:00 AM – 12:00 PM",
            "status": "pending",
            "street": "poy",
            "city": "oo",
            "landmark": "",
            "collector_name": "Nabeel",
            "created_at": "2026-11-20 11:26:51.741086+00:00"
          }
        ],
        "total_pickups": 10
      };

      final parsed = CollectorRoutePickupsResponse.fromJson(sampleJson);
      expect(parsed.collectorName, "nabeel");
      expect(parsed.totalPickups, 10);
      expect(parsed.assignedRoutes.length, 1);
      expect(parsed.assignedRoutes.first.district, "Thiruvananthapuram");
      expect(parsed.assignedRoutes.first.localBody, "Nedumangadu Municipality");
      expect(parsed.assignedRoutes.first.ward,
          ", KALLUVARAMBU, IRINCHIYAM, KUSARKODE");

      expect(parsed.pickups.length, 10);
      expect(parsed.pickups.first.pickupId, "601");
      expect(parsed.pickups.first.status, "rescheduled");
      expect(parsed.pickups.first.district, "Thiruvananthapuram");
      expect(parsed.pickups.first.localBody, "Nedumangadu Municipality");
      expect(parsed.pickups.first.street, "tvcra");
      expect(parsed.pickups.first.city, "csez");
      expect(parsed.pickups.first.pickupTimeSlot, "1:00");
    });
  });
}
