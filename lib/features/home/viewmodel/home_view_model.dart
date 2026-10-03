import 'package:floret_collector/providers/view_model.dart';
import '../model/home_model.dart';
import '../repos/home_repository.dart';

class HomeViewModel extends ViewModel {
  final HomeRepository _repository;
  HomeSummaryModel _summary = const HomeSummaryModel();
  bool _isShimmerLoading = true;

  HomeViewModel({HomeRepository? repository})
      : _repository = repository ?? HomeRepository() {
    loadHomeData();
  }

  HomeSummaryModel get summary => _summary;
  bool get isShimmerLoading => _isShimmerLoading;

  Future<void> loadHomeData({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isShimmerLoading = true;
      isLoading = true;
      notifyListeners();
    }

    final summaryFuture = _repository.fetchHomeSummary();

    if (!isRefresh) {
      // 3-second shimmer effect when user logs in / initial load
      await Future.wait([
        summaryFuture.then((value) => _summary = value),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      _isShimmerLoading = false;
    } else {
      _summary = await summaryFuture;
    }

    isLoading = false;
    notifyListeners();
  }
}
