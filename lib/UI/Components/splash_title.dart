import 'package:flutter/material.dart';
import 'gradient_text.dart'; // Import the new component

class SplashTitle extends StatelessWidget {

  final String text;
  final double? fontSize;

  const SplashTitle(this.text,this.fontSize,{super.key});

  @override
  Widget build(BuildContext context) {
    return GradientText(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFAA4B0F),
          Color(0xFFE19434),
          Color(0xFFDF4614),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }
}
