// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/constants/app_theme.dart';
//import 'package:google_fonts/google_fonts.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final String hintText;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onFilterTap,
    this.hintText = 'Find your coffee...',
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubLight,
            size: 24,
          ),
          suffixIcon: onFilterTap != null
              ? GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
