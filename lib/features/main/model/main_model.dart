enum MainNavTab {
  home,
  schedule,
  notification,
  menu,
}

class MainNavModel {
  final int selectedIndex;

  const MainNavModel({this.selectedIndex = 0});

  MainNavTab get currentTab => MainNavTab.values[selectedIndex];
}
