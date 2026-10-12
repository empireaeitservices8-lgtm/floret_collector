import 'package:floret_collector/providers/view_model.dart';
import '../model/schedule_model.dart';
import '../model/schedule_filter_model.dart';
import '../repos/schedule_repository.dart';

class ScheduleViewModel extends ViewModel {
  final ScheduleRepository _repository;
  ScheduleModel _schedule = const ScheduleModel();
  ScheduleFilterModel _filter = const ScheduleFilterModel();

  ScheduleViewModel({ScheduleRepository? repository})
      : _repository = repository ?? ScheduleRepository() {
    loadSchedule();
  }

  ScheduleModel get schedule => _schedule;
  ScheduleFilterModel get filter => _filter;

  String get wasteTypeDisplay {
    if (_filter.pickupType == PickupTypeFilter.sanitary) {
      return 'Sanitary waste';
    } else if (_filter.pickupType == PickupTypeFilter.scrap) {
      return 'Scrap waste';
    }
    return _schedule.wasteType;
  }

  void setFilter(ScheduleFilterModel newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void resetFilter() {
    _filter = const ScheduleFilterModel();
    notifyListeners();
  }

  Future<void> loadSchedule() async {
    isLoading = true;
    notifyListeners();

    _schedule = await _repository.fetchSchedule();

    isLoading = false;
    notifyListeners();
  }
}
