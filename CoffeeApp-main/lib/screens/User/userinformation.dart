

import 'dart:ui';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:coffeeapp/models/global_data.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:coffeeapp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UserInformation extends StatefulWidget {
  final bool isDark;
  final int index;
  const UserInformation({super.key, required this.isDark, required this.index});

  @override
  State<UserInformation> createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {

  Color get backgroundColor =>
      widget.isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get cardColor => widget.isDark ? AppColors.cardDark : Colors.white;
  Color get textColor =>
      widget.isDark ? AppColors.textMainDark : AppColors.textMainLight;
  Color get subTextColor =>
      widget.isDark ? AppColors.textSubDark : AppColors.textSubLight;

  final Map<String, Map<String, List<Color>>> rankGradients = {
    'bronze': {
      'primary': [Color(0xFFCD7F32), Color(0xFFB87333), Colors.white],
      'secondary': [Colors.white, Color(0xFFB87333), Color(0xFFCD7F32)],
    },
    'silver': {
      'primary': [Color(0xFFC0C0C0), Colors.grey, Colors.white],
      'secondary': [Colors.white, Colors.grey, Color(0xFFC0C0C0)],
    },
    'gold': {
      'primary': [Color(0xFFFFD700), Color(0xFFFFC107), Colors.white],
      'secondary': [Colors.white, Color(0xFFFFC107), Color(0xFFFFD700)],
    },
    'blue diamond': {
      'primary': [Colors.lightBlueAccent, Colors.blue, Colors.white],
      'secondary': [Colors.white, Colors.blueAccent, Colors.lightBlue],
    },
    'purple diamond': {
      'primary': [Colors.purpleAccent, Colors.deepPurple, Colors.white],
      'secondary': [Colors.white, Colors.deepPurpleAccent, Colors.purple],
    },
    'red diamond': {
      'primary': [Colors.redAccent, Colors.red, Colors.white],
      'secondary': [Colors.white, Colors.red, Colors.redAccent],
    },
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    var format = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(widget.isDark).color,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: textColor, size: 20),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Thông tin tài khoản',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }


          final currentRank = provider.currentRank;
          final rankGradientsList = rankGradients.entries.elementAt(
            currentRank < rankGradients.length ? currentRank : 0,
          );
          final rankImage = provider.ranks.entries
              .elementAt(currentRank < provider.ranks.length ? currentRank : 0)
              .value;

          return SafeArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: AnimateGradient(
                            primaryColors:
                                rankGradientsList.value.entries.first.value,
                            secondaryColors:
                                rankGradientsList.value.entries.last.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [

                                Positioned(
                                  right: -30,
                                  top: -30,
                                  child: Icon(
                                    Icons.star,
                                    size: 150,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundImage: AssetImage(
                                          GlobalData.userDetail.photoURL,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      GlobalData.userDetail.username,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        GlobalData.userDetail.rank,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),


                      _buildSectionTitle("Thống kê hoạt động"),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getShadow(widget.isDark).color,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              Icons.shopping_bag_outlined,
                              "Đơn hàng đã đặt",
                              "${provider.totalOrders}",
                              Colors.blueAccent,
                            ),
                            _buildDivider(),
                            _buildStatRow(
                              Icons.local_cafe_outlined,
                              "Số ly đã uống",
                              "${provider.totalDrinks}",
                              Colors.brown,
                            ),
                            _buildDivider(),
                            _buildStatRow(
                              Icons.payments_outlined,
                              "Tổng chi tiêu",
                              "${format.format(provider.totalPayment)} đ",
                              Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),


                      _buildSectionTitle("Đồ uống đã thử"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: provider.drinkList.map((drink) {
                          return Chip(
                            label: Text(
                              drink,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: cardColor,
                            avatar: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            elevation: 2,
                            shadowColor: Colors.black12,
                            padding: const EdgeInsets.all(10),
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),


                      Row(
                        children: [
                          _buildSectionTitle(
                            "Tiến trình thăng hạng",
                            noPadding: true,
                          ),
                          const Spacer(),
                          Image.asset(rankImage, width: 30, height: 30),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getShadow(widget.isDark).color,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: provider.rankProgress.clamp(0.0, 1.0),
                                minHeight: 12,
                                backgroundColor: widget.isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Cần thêm ${provider.pointsToNext} điểm để lên ${provider.ranks.entries.elementAt(provider.nextRank).key}",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),


                      _buildSectionTitle("Kho Voucher"),
                      SizedBox(
                        height: 150,
                        child: provider.coupons.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.discount_outlined,
                                      color: subTextColor,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Bạn chưa có voucher nào",
                                      style: TextStyle(color: subTextColor),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: provider.coupons.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 220,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: widget.isDark
                                          ? Color(0xFF2C2520)
                                          : Colors
                                                .orange[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.confirmation_number_outlined,
                                          color: Colors.orange,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          provider.coupons[index],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const Text(
                                          "Mã giảm giá đặc biệt",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 40),


                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(
                            Icons.lock_reset,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Đổi mật khẩu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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



  Widget _buildSectionTitle(String title, {bool noPadding = false}) {
    return Padding(
      padding: noPadding ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: widget.isDark ? Colors.grey[800] : Colors.grey[100],
      height: 1,
    );
  }


  Future<void> _showChangePasswordDialog() async {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool isOldVisible = false;
    bool isNewVisible = false;
    bool isConfirmVisible = false;
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.security, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Đổi mật khẩu",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    _buildPassField(
                      oldPassController,
                      "Mật khẩu cũ",
                      isOldVisible,
                      () => setStateDialog(() => isOldVisible = !isOldVisible),
                    ),
                    const SizedBox(height: 16),
                    _buildPassField(
                      newPassController,
                      "Mật khẩu mới",
                      isNewVisible,
                      () => setStateDialog(() => isNewVisible = !isNewVisible),
                    ),
                    const SizedBox(height: 16),
                    _buildPassField(
                      confirmPassController,
                      "Nhập lại mật khẩu mới",
                      isConfirmVisible,
                      () => setStateDialog(
                        () => isConfirmVisible = !isConfirmVisible,
                      ),
                    ),

                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.all(20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Hủy",
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final oldPass = oldPassController.text.trim();
                          final newPass = newPassController.text.trim();
                          final confirmPass = confirmPassController.text.trim();

                          if (oldPass.isEmpty ||
                              newPass.isEmpty ||
                              confirmPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "❗Vui lòng nhập đầy đủ thông tin.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "❌ Mật khẩu xác nhận không khớp.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isLoading = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser!;
                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: oldPass,
                            );
                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(newPass);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Đổi mật khẩu thành công!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("⚠️ Lỗi: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            setStateDialog(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Xác nhận",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPassField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: subTextColor,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: widget.isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
