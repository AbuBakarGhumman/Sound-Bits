import 'package:flutter/material.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive size
    final logoSize = screenWidth * 0.55; // roughly equivalent to 120 on standard device

    return Image.asset(
      'Asserts/logo1.png',
      height: logoSize,
      width: logoSize,
    );
  }
}
