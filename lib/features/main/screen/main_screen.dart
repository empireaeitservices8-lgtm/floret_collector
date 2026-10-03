import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/main_view_model.dart';
import '../../home/screen/home_screen.dart';
import '../../schedule/screen/schedule_screen.dart';
import '../../notification/screen/notification_screen.dart';
import '../../menu/screen/menu_screen.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = '/MainScreen';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainViewModel _viewModel;

  static const List<Widget> _screens = [
    HomeScreen(),
    ScheduleScreen(),
    NotificationScreen(),
    MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = MainViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainViewModel>.value(
      value: _viewModel,
      child: Consumer<MainViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            body: IndexedStack(
              index: vm.currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      _buildNavItem(
                        index: 0,
                        currentIndex: vm.currentIndex,
                        label: 'Home',
                        selectedIcon: Icons.home_rounded,
                        unselectedIcon: Icons.home_outlined,
                        onTap: () => vm.setIndex(0),
                      ),
                      _buildNavItem(
                        index: 1,
                        currentIndex: vm.currentIndex,
                        label: 'Schedule',
                        selectedIcon: Icons.calendar_month_rounded,
                        unselectedIcon: Icons.calendar_today_outlined,
                        onTap: () => vm.setIndex(1),
                      ),
                      _buildNavItem(
                        index: 2,
                        currentIndex: vm.currentIndex,
                        label: 'Notification',
                        selectedIcon: Icons.notifications_rounded,
                        unselectedIcon: Icons.notifications_none_rounded,
                        onTap: () => vm.setIndex(2),
                      ),
                      _buildNavItem(
                        index: 3,
                        currentIndex: vm.currentIndex,
                        label: 'Menu',
                        selectedIcon: Icons.menu_rounded,
                        unselectedIcon: Icons.menu_rounded,
                        onTap: () => vm.setIndex(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String label,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected
        ? const Color(0xFF1E293B)
        : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
