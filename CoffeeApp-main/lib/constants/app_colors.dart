// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFC6A969); // Warm Gold
  static const Color primarySoft = Color(0xFFF5EBDD); // Cream
  static const Color primaryDark = Color(0xFF3B2F2F); // Espresso Brown

  // Premium Palette Additions
  static const Color espressoBrown = Color(0xFF3B2F2F);
  static const Color cream = Color(0xFFF5EBDD);
  static const Color warmGold = Color(0xFFC6A969);
  static const Color tintBackground = Color(0xFFFAF8F5);

  // Background and Surface Colors
  static const Color backgroundLight = Color(
    0xFFFAF8F5,
  ); // Updated to Tint Background
  static const Color backgroundDark = Color(0xFF111315);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1F2225);

  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD700);
  static const Color info = Color(0xFF3B82F6);

  static const Color textMainLight = Color(0xFF1F2937);
  static const Color textMainDark = Color(0xFFF3F4F6);
  static const Color textSubLight = Color(0xFF6B7280);
  static const Color textSubDark = Color(0xFF9CA3AF);

  static const Color pastelGreen = Color(0xFFE6F4EA);
  static const Color pastelBlue = Color(0xFFE3F2FD);
  static const Color pastelOrange = Color(0xFFFFF3E0);
  static const Color pastelPink = Color(0xFFFCE4EC);
  static const Color pastelPurple = Color(0xFFF3E5F5);

  static BoxShadow softShadow = BoxShadow(
    color: const Color(0xFF3B2F2F).withOpacity(0.04), // Softer Espresso shadow
    blurRadius: 16,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );

  static BoxShadow cardShadow = BoxShadow(
    color: const Color(0xFF3B2F2F).withOpacity(0.03),
    blurRadius: 12,
    offset: const Offset(0, 2),
    spreadRadius: 0,
  );

  static BoxShadow darkShadow = BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 16,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );

  static const Color secondary = primarySoft;
  static const Color accent = success;
  static const Color cardLight = surfaceLight;
  static const Color cardDark = surfaceDark;

  static BoxShadow getShadow(bool isDark) => isDark ? darkShadow : softShadow;

  static const Color primaryColor = primary;
  static const Color backgroundColor = backgroundLight;
  static const Color surfaceColor = surfaceLight;
  static const Color textMain = textMainLight;
}
