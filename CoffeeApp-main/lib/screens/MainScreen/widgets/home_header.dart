// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/models/global_data.dart';
import 'package:coffeeapp/widgets/app_image.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  final bool isDark;

  const HomeHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark
        ? AppColors.textMainDark
        : AppColors.espressoBrown;
    final Color subTextColor = isDark
        ? AppColors.textSubDark
        : AppColors.espressoBrown.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Xin chào,",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  GlobalData.userDetail.username.isNotEmpty
                      ? GlobalData.userDetail.username
                      : "Khách hàng",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: textColor,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(width: 12),

              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warmGold, width: 2),
                ),
                child: ClipOval(
                  child: AppImage(
                    imageUrl: GlobalData.userDetail.photoURL.isNotEmpty
                        ? GlobalData.userDetail.photoURL
                        : "assets/images/avatar/user.png",
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
