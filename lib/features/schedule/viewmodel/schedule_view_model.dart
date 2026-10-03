import 'package:floret_collector/providers/view_model.dart';
import '../model/schedule_model.dart';
import '../repos/schedule_repository.dart';

class ScheduleViewModel extends ViewModel {
  final ScheduleRepository _repository;
  ScheduleModel _schedule = const ScheduleModel();

  ScheduleViewModel({ScheduleRepository? repository})
      : _repository = repository ?? ScheduleRepository() {
    loadSchedule();
  }

  ScheduleModel get schedule => _schedule;

  Future<void> loadSchedule() async {
    isLoading = true;
    notifyListeners();

    _schedule = await _repository.fetchSchedule();

    isLoading = false;
    notifyListeners();
  }
}
