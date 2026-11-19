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

  List<IssueModel> get openIssues {
    final list = _allIssues.where((i) => !i.isResolved).toList();
    list.sort((a, b) {
      final dateA = DateTime.tryParse(a.createdAt ?? '');
      final dateB = DateTime.tryParse(b.createdAt ?? '');
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA); // Newest first
      } else if (dateB != null) {
        return 1;
      } else if (dateA != null) {
        return -1;
      }
      return 0;
    });
    return list;
  }

  List<IssueModel> get resolvedIssues {
    final list = _allIssues.where((i) => i.isResolved).toList();
    list.sort((a, b) {
      final dateA = DateTime.tryParse(a.resolvedAt ?? a.createdAt ?? '');
      final dateB = DateTime.tryParse(b.resolvedAt ?? b.createdAt ?? '');
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA); // Newest first
      } else if (dateB != null) {
        return 1;
      } else if (dateA != null) {
        return -1;
      }
      return 0;
    });
    return list;
  }

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

  Future<bool> resolveIssue({
    required IssueModel issue,
    required String resolutionNotes,
  }) async {
    final success = await _repository.resolveIssue(
      issueId: issue.id,
      pickupId: issue.pickupId,
      resolutionNotes: resolutionNotes,
    );

    if (success) {
      final index = _allIssues.indexWhere((i) => i.id == issue.id);
      if (index != -1) {
        _allIssues[index] = _allIssues[index].copyWith(
          isResolved: true,
          resolutionNotes: resolutionNotes,
          resolvedAt: DateTime.now().toIso8601String(),
        );
        notifyListeners();
      }
      _allIssues = await _repository.fetchIssues();
      notifyListeners();
    }
    return success;
  }
}
