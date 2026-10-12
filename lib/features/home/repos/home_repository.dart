import 'package:floret_collector/features/home/model/bag_model.dart';
import 'package:floret_collector/features/home/model/pickup_slot_model.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';

abstract class HomeRepository {
  Future<PickupSlotsResponseModel> getPickupSlots();
  Future<List<BagModel>> getBags();
  Future<BagModel> getBagDetails(int id);
}

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient apiClient;

  HomeRepositoryImpl(this.apiClient);

  @override
  Future<PickupSlotsResponseModel> getPickupSlots() async {
    final response = await apiClient.get(
      APIEndPoints.pickupSlots,
    );

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
}
