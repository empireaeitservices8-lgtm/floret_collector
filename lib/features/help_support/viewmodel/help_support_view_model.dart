import 'dart:async';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/faq_item_model.dart';
import '../model/help_support_model.dart';
import '../repos/help_support_repository.dart';

class HelpSupportViewModel extends ViewModel {
  final HelpSupportRepository _repository;

  List<FaqItemModel> _faqs = [];
  HelpSupportModel? _supportInfo;
  String _searchQuery = '';
  bool _isRefreshing = false;
  final Set<String> _expandedIds = {};

  HelpSupportViewModel({HelpSupportRepository? repository})
      : _repository = repository ??
            (getIt.isRegistered<HelpSupportRepository>()
                ? getIt<HelpSupportRepository>()
                : HelpSupportRepository()) {
    loadData();
  }

  List<FaqItemModel> get faqs => _faqs;
  HelpSupportModel? get supportInfo => _supportInfo;
  String get searchQuery => _searchQuery;
  bool get isRefreshing => _isRefreshing;
  Set<String> get expandedIds => _expandedIds;

  String get supportPhone =>
      _supportInfo?.contact.phoneFormatted ?? '+91 92920 23601';

  String get supportEmail =>
      _supportInfo?.contact.email ?? 'florettechnologi...';

  bool isExpanded(String id) => _expandedIds.contains(id);

  List<FaqItemModel> get filteredFaqs {
    if (_searchQuery.trim().isEmpty) return _faqs;
    final query = _searchQuery.trim().toLowerCase();
    return _faqs.where((faq) {
      final questionMatches = faq.question.toLowerCase().contains(query);
      final answerMatches = faq.answer.toLowerCase().contains(query);
      return questionMatches || answerMatches;
    }).toList();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadFaqs(),
      loadSupportInfo(),
    ]);
  }

  Future<void> loadFaqs() async {
    _faqs = await _repository.fetchFaqs();
    notifyListeners();
  }

  Future<void> loadSupportInfo() async {
    _supportInfo = await _repository.fetchHelpSupport();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleExpanded(String id) {
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
    } else {
      _expandedIds.add(id);
    }
    notifyListeners();
  }

  Future<void> refresh({int delaySeconds = 3}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    await Future.delayed(Duration(seconds: delaySeconds));

    _faqs = await _repository.fetchFaqs();
    _supportInfo = await _repository.fetchHelpSupport();
    _isRefreshing = false;
    notifyListeners();
  }
}
