import 'dart:convert';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import '../model/faq_item_model.dart';
import '../model/help_support_model.dart';

class HelpSupportRepository {
  final ApiClient _apiClient;

  HelpSupportRepository({ApiClient? apiClient})
      : _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : ApiClient());

  ApiClient get apiClient => _apiClient;

  HelpSupportModel? _helpSupportInfo;
  HelpSupportModel? get helpSupportInfo => _helpSupportInfo;

  Future<HelpSupportModel?> fetchHelpSupport() async {
    try {
      final response = await _apiClient.get(APIEndPoints.helpSupport);

      // Print response formatted like the API response
      try {
        const encoder = JsonEncoder.withIndent('  ');
        final formattedJson = encoder.convert(response.data);
        // ignore: avoid_print
        print(formattedJson);
      } catch (_) {
        // ignore: avoid_print
        print(response.data);
      }

      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        _helpSupportInfo = HelpSupportModel.fromJson(data);
        return _helpSupportInfo;
      }
    } catch (_) {}

    return _helpSupportInfo;
  }

  final List<FaqItemModel> _faqs = const [
    FaqItemModel(
      id: '1',
      question: 'How do I confirm a cash payment?',
      answer:
          "To confirm a cash payment, weigh the waste at the stop, select the 'Cash' payment method, confirm the total calculated fee (including GST), and tap 'Yes, Received' once the cash is collected.",
    ),
    FaqItemModel(
      id: '2',
      question: 'What should I do if the online payment QR code fails to load?',
      answer:
          "If the QR code does not load, verify your internet connection. You can try refreshing the payment screen, send the payment link to the customer's phone, or fallback to cash collection if the customer prefers.",
    ),
    FaqItemModel(
      id: '3',
      question: 'How is the total waste collection fee calculated?',
      answer:
          'The total fee is calculated as: Base Service Fee (₹120) + (Waste Weight × Assigned Rate/kg) + 5% GST.',
    ),
    FaqItemModel(
      id: '4',
      question: 'How do I report unsorted waste or locked gates?',
      answer:
          "On the navigation map or pickup details screen, tap 'Report Issue'. Select the category (e.g. Unsorted Waste, Gate Locked, Refused to Pay), add details, and submit. The system will log it for administration review.",
    ),
    FaqItemModel(
      id: '5',
      question: 'How do I update my ward or collection route?',
      answer:
          "Go to the sidebar menu on the home screen, select 'Select Ward', choose your District, Local Body, and Ward. Tap 'Proceed' to fetch the routes and stops for that ward.",
    ),
    FaqItemModel(
      id: '6',
      question: 'Can I use multiple bags for a single stop?',
      answer:
          'Yes. When recording the waste, you can select the number of bags utilized. The bag fee (₹7/bag) will be added to the customer\'s grand total automatically.',
    ),
  ];

  Future<List<FaqItemModel>> fetchFaqs() async {
    return List.from(_faqs);
  }
}
