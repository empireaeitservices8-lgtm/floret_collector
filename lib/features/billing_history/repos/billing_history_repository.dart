import '../model/billing_history_model.dart';
import 'package:floret_collector/services/web_api_services.dart';

class BillingHistoryRepository {
  final WebAPIService _webAPIService;

  BillingHistoryRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  WebAPIService get webAPIService => _webAPIService;

  Future<List<BillItemModel>> fetchBills() async {
    try {
      // Mock data matching exact bills shown in design screenshots
      return const [
        BillItemModel(
          id: '234',
          stopId: '77',
          stopName: 'ne',
          weight: '0.0',
          rate: '42.00',
          amount: '16.52',
          method: 'Cash',
          status: 'Paid',
          date: '10 Sep 2026, 02:25 PM',
        ),
        BillItemModel(
          id: '233',
          stopId: '77',
          stopName: 'ne',
          weight: '0.0',
          rate: '10.00',
          amount: '24.78',
          method: 'Cash',
          status: 'Paid',
          date: '10 Sep 2026, 02:25 PM',
        ),
        BillItemModel(
          id: '232',
          stopId: '23',
          stopName: 'jos',
          weight: '0.0',
          rate: '42.00',
          amount: '16.52',
          method: 'Cash',
          status: 'Paid',
          date: '10 Sep 2026, 02:23 PM',
        ),
        BillItemModel(
          id: '179',
          stopId: '12',
          stopName: 'jos',
          weight: '50.5',
          rate: '2.00',
          amount: '101.00',
          method: 'Online',
          status: 'Paid',
          date: '05 Sep 2026, 12:45 PM',
        ),
        BillItemModel(
          id: '178',
          stopId: '12',
          stopName: 'jos',
          weight: '50.5',
          rate: '2.00',
          amount: '101.00',
          method: 'Online',
          status: 'Paid',
          date: '05 Sep 2026, 12:44 PM',
        ),
        BillItemModel(
          id: '177',
          stopId: '13',
          stopName: 'jos',
          weight: '17.5',
          rate: '2.50',
          amount: '43.75',
          method: 'Online',
          status: 'Paid',
          date: '05 Sep 2026, 12:44 PM',
        ),
        BillItemModel(
          id: '165',
          stopId: '09',
          stopName: 'ne',
          weight: '12.0',
          rate: '5.00',
          amount: '60.00',
          method: 'Cash',
          status: 'Pending',
          date: '01 Sep 2026, 10:15 AM',
        ),
      ];
    } catch (_) {
      return [];
    }
  }
}
