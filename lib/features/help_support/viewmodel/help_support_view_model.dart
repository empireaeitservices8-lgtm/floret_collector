import 'dart:async';
import 'package:floret_collector/providers/view_model.dart';
import '../model/faq_item_model.dart';
import '../repos/help_support_repository.dart';

class HelpSupportViewModel extends ViewModel {
  final HelpSupportRepository _repository;

  List<FaqItemModel> _faqs = [];
  String _searchQuery = '';
  bool _isRefreshing = false;
  final Set<String> _expandedIds = {};

  HelpSupportViewModel({HelpSupportRepository? repository})
      : _repository = repository ?? HelpSupportRepository() {
    loadFaqs();
  }

  List<FaqItemModel> get faqs => _faqs;
  String get searchQuery => _searchQuery;
  bool get isRefreshing => _isRefreshing;
  Set<String> get expandedIds => _expandedIds;

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

  Future<void> loadFaqs() async {
    _faqs = await _repository.fetchFaqs();
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

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    _faqs = await _repository.fetchFaqs();
    _isRefreshing = false;
    notifyListeners();
  }
}
