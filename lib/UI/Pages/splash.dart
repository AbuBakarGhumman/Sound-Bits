import 'package:flutter/material.dart';
import '../../Constants/app_constants.dart';
import '../Components/splash_logo.dart';
import '../Components/splash_title.dart';

class MSplashPage extends StatefulWidget {
  const MSplashPage({super.key});

  @override
  State<MSplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<MSplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/mHome');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔹 Responsive ratios
    final logoSpacing = screenHeight * 0.0001;
    final logo_Spacing = screenHeight * 0.01;
    final titleFontSize = screenWidth * 0.085;
    final bottomSpacing = screenHeight * 0.025;
    final bottomSmallTextSize = screenWidth * 0.042;
    final bottomTitleFontSize = screenWidth * 0.048;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Center content (logo, title, etc)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SplashLogo(),
                SplashTitle(
                  AppConstants.appName,
                  titleFontSize,
                ),
                //SizedBox(height: logo_Spacing),
                // Example loader with responsive width
                 //BarLoader(screenWidth * 0.5, Duration(seconds: 5)),
              ],
            ),
          ),

          // Bottom center text
          Positioned(
            bottom: bottomSpacing,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'from',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: bottomSmallTextSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                SplashTitle(
                  'GH Developers',
                  bottomTitleFontSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
