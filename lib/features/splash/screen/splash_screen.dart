import 'package:floret_collector/core/di/injection.dart';
import 'package:flutter/material.dart';

import 'package:floret_collector/features/splash/viewmodel/splash_view_model.dart';
import 'package:floret_collector/features/login/screen/login_screen.dart';
import 'package:floret_collector/features/main/screen/main_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/SplashScreen';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashViewModel _viewModel;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _viewModel = getIt<SplashViewModel>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check token and maintain minimum splash duration
    final results = await Future.wait([
      _viewModel.checkLoginStatus(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    final isLoggedIn = results.first as bool;

    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? MainScreen.routeName : LoginScreen.routeName,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Floret Technologies Logo
              Image.asset(
                'assets/images/floret_logo.png',
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'Floret Technologies',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB89552),
                      letterSpacing: 1.2,
                    ),
                  );
                },
              ),

              const SizedBox(height: 52),

              // Loading Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const SizedBox(
                  width: 72,
                  height: 4,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFECEBF5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF7065C2),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
