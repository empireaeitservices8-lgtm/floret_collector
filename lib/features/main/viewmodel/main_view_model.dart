import 'package:floret_collector/providers/view_model.dart';
import '../model/main_model.dart';

class MainViewModel extends ViewModel {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  MainNavTab get currentTab => MainNavTab.values[_currentIndex];

  void setIndex(int index) {
    if (index >= 0 && index < MainNavTab.values.length && _currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
