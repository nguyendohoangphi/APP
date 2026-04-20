// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:coffeeapp/screens/Login_Register/login_screen.dart';
import 'package:coffeeapp/screens/Login_Register/register_screen.dart';

class AppTheme {
  static const Color primary = Color(0xFFB2640A);
  static const backgroundLight = Color(0xFFF8F7F5);
  static const textMain = Color(0xFF1C150D);
  static const textSub = Color(0xFF9C7649);
  static const borderLight = Color(0xFFE8DCCE);
  static const white = Colors.white;
}

class CoffeeLoginRegisterScreen extends StatefulWidget {
  const CoffeeLoginRegisterScreen({super.key});

  @override
  State<CoffeeLoginRegisterScreen> createState() =>
      _CoffeeLoginRegisterScreenState();
}

class _CoffeeLoginRegisterScreenState extends State<CoffeeLoginRegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signOut();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentPage == 0 ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          color: AppTheme.textMain,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPage == 0
                            ? 'Please sign in to continue your coffee journey.'
                            : 'Join us to start brewing happiness.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSub,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 32),


                      SizedBox(
                        height: _currentPage == 0 ? 320 : 420,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          children: [
                            LoginScreen(
                              setLoading: _setLoading,
                              showMessage: _showMessage,
                            ),
                            RegisterScreen(
                              setLoading: _setLoading,
                              showMessage: _showMessage,
                              onRegisterSuccess: () => _navigateToPage(0),
                            ),
                          ],
                        ),
                      ),


                      if (_currentPage == 0) ...[
                        const SizedBox(height: 10),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialButtons(),
                        const SizedBox(height: 32),
                      ],


                      _buildBottomNav(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),


          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/background/loading.json',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildHeroHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 320,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(48),
            ),
            image: DecorationImage(
              image: AssetImage('assets/background/login_hero.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(48),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundLight.withOpacity(0.0),
                  AppTheme.backgroundLight.withOpacity(0.4),
                  AppTheme.backgroundLight,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          child: Column(
            children: [
              Transform.rotate(
                angle: 3 * math.pi / 180,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.coffee,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PhINoM',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'BREWING HAPPINESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Divider(color: AppTheme.borderLight),
        Container(
          color: AppTheme.backgroundLight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Text(
            'Or continue with',
            style: TextStyle(
              color: AppTheme.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton('assets/icons/google.svg'),
        const SizedBox(width: 20),
        _socialButton('assets/icons/apple.svg'),
      ],
    );
  }

  Widget _socialButton(String assetPath) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.white,
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(assetPath),
    );
  }

  Widget _buildBottomNav() {
    bool isLogin = _currentPage == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? 'New to PhINoM? ' : 'Already have an account? ',
          style: const TextStyle(color: AppTheme.textMain, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            if (isLogin) {
              _navigateToPage(1);
            } else {
              _navigateToPage(0);
            }
          },
          child: Text(
            isLogin ? 'Create Account' : 'Log In',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}




class ModernTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const ModernTextField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textMain),
        decoration: InputDecoration(
          filled: false,
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textSub.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: AppTheme.textSub),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

class ModernPasswordField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggle;

  const ModernPasswordField({
    super.key,
    required this.hint,
    required this.controller,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(color: AppTheme.textMain),
        decoration: InputDecoration(
          filled: false,
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textSub.withOpacity(0.6)),
          prefixIcon: const Icon(Symbols.lock, color: AppTheme.textSub),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Symbols.visibility : Symbols.visibility_off,
              color: AppTheme.textSub,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ActionButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          elevation: 8,
          shadowColor: AppTheme.primary.withOpacity(0.3),
          shape: const StadiumBorder(),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
