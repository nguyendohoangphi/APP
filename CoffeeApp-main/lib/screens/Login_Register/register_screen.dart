import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:coffeeapp/screens/Login_Register/coffeeloginregisterscreen.dart';
import 'package:coffeeapp/services/firebase_db_manager.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(bool) setLoading;
  final void Function(String, {bool isError}) showMessage;
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({
    super.key,
    required this.setLoading,
    required this.showMessage,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      widget.showMessage("Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      widget.showMessage("Mật khẩu không khớp");
      return;
    }

    widget.setLoading(true);
    final result = await FirebaseDBManager.authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    widget.setLoading(false);

    if (result == "OK") {
      widget.showMessage(
        "Đăng ký thành công! Vui lòng đăng nhập.",
        isError: false,
      );
      widget.onRegisterSuccess();
    } else {
      widget.showMessage(result ?? "Đăng ký thất bại.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernTextField(
          hint: "Full Name",
          icon: Symbols.person,
          controller: _usernameController,
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        ModernPasswordField(
          hint: "Confirm Password",
          controller: _confirmController,
          isVisible: _showConfirm,
          onToggle: () => setState(() => _showConfirm = !_showConfirm),
        ),
        const SizedBox(height: 24),
        ActionButton(text: "CREATE ACCOUNT", onPressed: _handleRegister),
      ],
    );
  }
}
