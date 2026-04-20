//import 'package:provider/provider.dart';
//import 'package:coffeeapp/providers/cart_provider.dart';
import 'package:coffeeapp/screens/Order/cart.dart';
import 'package:coffeeapp/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:coffeeapp/screens/MainScreen/category.dart';
import 'package:coffeeapp/screens/MainScreen/home.dart';
import 'package:coffeeapp/screens/MainScreen/profile.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
//import 'package:badges/badges.dart' as badges;

import 'package:coffeeapp/screens/chat_screen.dart';
import 'package:coffeeapp/screens/Store/store_locator_screen.dart';

class MenuNavigationBar extends StatefulWidget {
  final bool isDark;
  final int selectedIndex;

  const MenuNavigationBar({
    required this.isDark,
    required this.selectedIndex,
    super.key,
  });

  @override
  State<MenuNavigationBar> createState() => _MenuNavigationBarState();
}

class _MenuNavigationBarState extends State<MenuNavigationBar> {
  late bool _isDark;
  late int _selectedIndex;
  Offset? _fabPosition;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    _selectedIndex = widget.selectedIndex;
  }

  void updateDarkMode(bool value) {
    setState(() {
      _isDark = value;
    });
  }

  void refreshCart() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_fabPosition == null) {
      final size = MediaQuery.of(context).size;
      // Trừ đi kích thước nút và thanh bottom navigation để đặt vị trí ban đầu
      _fabPosition = Offset(size.width - 70, size.height - 160);
    }

    final List<Widget> pages = [
      Home(isDark: _isDark, onDarkChanged: updateDarkMode),
      Category(isDark: _isDark, onDarkChanged: updateDarkMode),
      Cart(isDark: _isDark, index: 2, isTab: true),
      StoreLocatorScreen(isDark: _isDark),
      Profile(isDark: _isDark),
    ];

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: _isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,

          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedIndex),
              child: pages[_selectedIndex],
            ),
          ),

          bottomNavigationBar: SafeArea(
            bottom: true,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              decoration: BoxDecoration(
                color: _isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                child: GNav(
                  gap: 6,
                  backgroundColor: Colors.transparent,
                  color: _isDark ? Colors.grey[400] : Colors.grey[600],
                  activeColor: Colors.white,
                  iconSize: 22,
                  tabBackgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  tabs: const [
                    GButton(icon: Icons.home_rounded, text: 'Trang chủ'),
                    GButton(icon: Icons.grid_view_rounded, text: 'Thực đơn'),
                    GButton(
                      icon: Icons.shopping_cart_rounded,
                      text: 'Giỏ hàng',
                    ),
                    GButton(icon: Icons.storefront_rounded, text: 'Cửa hàng'),
                    GButton(icon: Icons.person_rounded, text: 'Tài khoản'),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: _fabPosition!.dx,
          top: _fabPosition!.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final size = MediaQuery.of(context).size;
                double newX = _fabPosition!.dx + details.delta.dx;
                double newY = _fabPosition!.dy + details.delta.dy;

                // Giới hạn để nút không bị kéo ra ngoài màn hình
                newX = newX.clamp(0.0, size.width - 56);
                newY = newY.clamp(0.0, size.height - 56);

                _fabPosition = Offset(newX, newY);
              });
            },
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(isDark: _isDark),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
