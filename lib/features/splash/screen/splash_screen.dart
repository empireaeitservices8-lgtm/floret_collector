import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/splash_view_model.dart';
import '../../login/screen/login_screen.dart';

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
    _viewModel = SplashViewModel();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize(
        context,
        onComplete: () {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        },
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SplashViewModel>.value(
      value: _viewModel,
      child: Scaffold(
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
                // Smooth Horizontal Progress Indicator matching design
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
      ),
    );
  }
}
