import 'package:flutter/material.dart';
import '../services/apiAuth.dart';
import 'profile_screen.dart';
import '../constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;

  void _handleAuth() async {
    final userName = _userController.text.trim();
    final password = _passController.text.trim();

    if (userName.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() => isLoading = true);

    // Gọi đến AuthService
    final result = isLogin
        ? await _authService.login(userName, password)
        : await _authService.register(userName, password);

    setState(() => isLoading = false);

    print(result);

    if (result['success']) {
      if (isLogin) {
        _showSnackBar("Đăng nhập thành công!", isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        _showSnackBar("Đăng ký thành công! Mời bạn đăng nhập", isError: false);
        setState(() => isLogin = true);
        _passController.clear();
      }
    } else {
      // Hiển thị lỗi từ backend trả về
      _showSnackBar(result['message']);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isLogin ? Icons.lock_outline : Icons.person_add_outlined,
                  size: 80, color: kPrimaryPink),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Chào mừng trở lại" : "Tạo tài khoản mới",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: kPrimaryPink,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? "Đăng nhập" : "Đăng ký",
                      style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}