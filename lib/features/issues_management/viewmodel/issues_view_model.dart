import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/issue_model.dart';
import '../repos/issues_repository.dart';

enum IssueTab { issues, resolved }

class IssuesViewModel extends ViewModel {
  final IssuesRepository _repository;

  IssueTab _selectedTab = IssueTab.issues;
  bool _isRefreshing = false;
  List<IssueModel> _allIssues = [];
  int _refreshCounter = 0;

  IssuesViewModel({IssuesRepository? repository})
      : _repository = repository ??
            (getIt.isRegistered<IssuesRepository>()
                ? getIt<IssuesRepository>()
                : IssuesRepository()) {
    loadData();
  }

  IssueTab get selectedTab => _selectedTab;
  bool get isRefreshing => _isRefreshing;

  List<IssueModel> get openIssues =>
      _allIssues.where((i) => !i.isResolved).toList();

  List<IssueModel> get resolvedIssues =>
      _allIssues.where((i) => i.isResolved).toList();

  List<IssueModel> get currentTabIssues =>
      _selectedTab == IssueTab.issues ? openIssues : resolvedIssues;

  int get openCount => openIssues.length;
  int get resolvedCount => resolvedIssues.length;

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    _allIssues = await _repository.fetchIssues();

    isLoading = false;
    notifyListeners();
  }

  void setSelectedTab(IssueTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  Future<void> refresh({int delaySeconds = 3}) async {
    final currentId = ++_refreshCounter;
    _isRefreshing = true;
    notifyListeners();

    // Refresh button should show Circular progress indicator for 3sec
    await Future.delayed(Duration(seconds: delaySeconds));
    if (currentId != _refreshCounter) return;

    _allIssues = await _repository.fetchIssues();

    if (currentId == _refreshCounter) {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
