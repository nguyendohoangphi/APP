import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:coffeeapp/screens/Login_Register/coffeeloginregisterscreen.dart';
import 'package:coffeeapp/screens/Login_Register/forgot_password_screen.dart'
    hide AppTheme;
import 'package:coffeeapp/services/firebase_db_manager.dart';
import 'package:coffeeapp/models/global_data.dart';
import 'package:coffeeapp/Transition/auth_route_manager.dart';

class LoginScreen extends StatefulWidget {
  final void Function(bool) setLoading;
  final void Function(String, {bool isError}) showMessage;

  const LoginScreen({
    super.key,
    required this.setLoading,
    required this.showMessage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      widget.showMessage("Vui lòng nhập email và mật khẩu");
      return;
    }

    widget.setLoading(true);

    try {
      final result = await FirebaseDBManager.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result != "OK") {
        widget.showMessage(result ?? "Đăng nhập thất bại");
        return;
      }

      final profile = await FirebaseDBManager.authService.getProfile();

      if (profile == null) {
        widget.showMessage("Không thể lấy thông tin người dùng!");
        return;
      }

      GlobalData.userDetail = profile;
      if (mounted) {
        AuthRouteManager.goToHome(context, profile.role);
      }
    } catch (e) {
      widget.showMessage("Có lỗi xảy ra, vui lòng thử lại");
    } finally {
      if (mounted) {
        widget.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernTextField(
          hint: "Email Address",
          icon: Symbols.mail,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        ModernPasswordField(
          hint: "Password",
          controller: _passwordController,
          isVisible: _showPassword,
          onToggle: () => setState(() => _showPassword = !_showPassword),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: const Text(
              "Forgot Password?",
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        ActionButton(text: "LOG IN", onPressed: _handleLogin),
      ],
    );
  }
}
