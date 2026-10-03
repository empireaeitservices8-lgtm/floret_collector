import '../model/schedule_model.dart';
import 'package:floret_collector/services/web_api_services.dart';

class ScheduleRepository {
  final WebAPIService _webAPIService;

  ScheduleRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  WebAPIService get webAPIService => _webAPIService;

  Future<ScheduleModel> fetchSchedule({DateTime? date}) async {
    try {
      return const ScheduleModel(
        dateText: 'Wed, 30th Sep',
        progressText: '0 of 0 completed',
        sanitaryPickups: '0/0',
        scrapPickups: '0/0',
        wasteType: 'Sanitary & Scrap waste',
        progressPercent: 0.0,
        pickups: [],
      );
    } catch (_) {
      return const ScheduleModel();
    }
  }
}
