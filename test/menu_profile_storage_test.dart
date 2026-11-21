import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/features/menu/model/menu_model.dart';
import 'package:floret_collector/features/menu/repos/menu_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('CollectorLocalStorage saves and retrieves name, phone, and vehicle details', () async {
    final storage = CollectorLocalStorage();

    await storage.saveCollectorDetails(
      name: 'John Doe',
      phone: '+91 9876543210',
      vehicleName: 'Tata Ace',
      vehicleNumber: 'KL-07-CD-5678',
      vehicleStatus: 'Active',
    );

    final name = await storage.getSavedName();
    final phone = await storage.getSavedPhone();
    final vName = await storage.getSavedVehicleName();
    final vNumber = await storage.getSavedVehicleNumber();

    expect(name, 'John Doe');
    expect(phone, '+91 9876543210');
    expect(vName, 'Tata Ace');
    expect(vNumber, 'KL-07-CD-5678');
  });

  test('MenuRepository saves profile locally and retrieves cached profile immediately', () async {
    final storage = CollectorLocalStorage();
    final repository = MenuRepository(collectorLocalStorage: storage);

    const testProfile = UserProfileModel(
      collectorId: '101',
      name: 'Jane Smith',
      phone: '+91 9123456789',
      vehicleName: 'Mahindra Bolero',
      vehicleStatus: 'Assigned',
      regNo: 'KL-04-XY-9999',
      ward: 'Ward 12',
      localBody: 'Kochi Corp',
      district: 'Ernakulam',
      aadhaarStatus: 'Verified On File',
    );

    await repository.saveUserProfileLocally(testProfile);

    final cached = await repository.getCachedUserProfile();
    expect(cached, isNotNull);
    expect(cached!.name, 'Jane Smith');
    expect(cached.phone, '+91 9123456789');
    expect(cached.vehicleName, 'Mahindra Bolero');
    expect(cached.regNo, 'KL-04-XY-9999');
    expect(cached.ward, 'Ward 12');
    expect(cached.localBody, 'Kochi Corp');
    expect(cached.district, 'Ernakulam');
    expect(await storage.getSavedLocalBody(), 'Kochi Corp');
    expect(await storage.getSavedDistrict(), 'Ernakulam');
    expect(await storage.getSavedWard(), 'Ward 12');
  });

  test('CollectorLocalStorage saves and cleans ward with leading commas', () async {
    final storage = CollectorLocalStorage();
    final repository = MenuRepository(collectorLocalStorage: storage);

    const testProfile = UserProfileModel(
      collectorId: '102',
      name: 'Nabeel',
      phone: '+91 9999999999',
      ward: ', KALLUVARAMBU, IRINCHIYAM, KUSARKODE',
      localBody: 'Nedumangadu Municipality',
      district: 'Thiruvananthapuram',
    );

    await repository.saveUserProfileLocally(testProfile);
    expect(await storage.getSavedWard(), 'KALLUVARAMBU, IRINCHIYAM, KUSARKODE');

    final cached = await repository.getCachedUserProfile();
    expect(cached, isNotNull);
    expect(cached!.ward, 'KALLUVARAMBU, IRINCHIYAM, KUSARKODE');
  });

  test('MenuRepository logout clears all locally saved profile, name, phone, and vehicle details', () async {
    final storage = CollectorLocalStorage();
    final repository = MenuRepository(collectorLocalStorage: storage);

    const testProfile = UserProfileModel(
      collectorId: '101',
      name: 'Jane Smith',
      phone: '+91 9123456789',
      vehicleName: 'Mahindra Bolero',
      vehicleStatus: 'Assigned',
      regNo: 'KL-04-XY-9999',
    );

    await repository.saveUserProfileLocally(testProfile);

    // Verify it is present before logout
    expect(await storage.getSavedName(), 'Jane Smith');
    expect(await storage.getSavedPhone(), '+91 9123456789');
    expect(await storage.getSavedVehicleName(), 'Mahindra Bolero');
    expect(await storage.getSavedVehicleNumber(), 'KL-04-XY-9999');

    // Perform logout
    await repository.logout();

    // Verify all data is wiped
    expect(await storage.getSavedName(), isNull);
    expect(await storage.getSavedPhone(), isNull);
    expect(await storage.getSavedVehicleName(), isNull);
    expect(await storage.getSavedVehicleNumber(), isNull);
    expect(await storage.getSavedLocalBody(), isNull);
    expect(await storage.getSavedDistrict(), isNull);
    expect(await storage.getSavedWard(), isNull);
    expect(await storage.getCollector(), isNull);
    expect(await repository.getCachedUserProfile(), isNull);
  });
}
