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
  final TextEditingController _emailController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;

  void _handleAuth() async {
    final userName = _userController.text.trim();
    final password = _passController.text.trim();
    final email = _emailController.text.trim();

    if (userName.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (!isLogin && email.isEmpty) {
      _showSnackBar("Vui lòng nhập thêm địa chỉ Email khi đăng ký");
      return;
    }

    setState(() => isLoading = true);

    // Gọi đến AuthService
    final result = isLogin
        ? await _authService.login(userName, password)
        : await _authService.register(userName, password, email);

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

  // Quên pw
  void _showForgotPasswordDialog() {
    final TextEditingController dialogEmailController = TextEditingController();
    final TextEditingController dialogOtpController = TextEditingController();
    final TextEditingController dialogNewPassController = TextEditingController();

    int currentStep = 1; // 1: Nhập Email, 2: Nhập OTP & Pass mới
    bool isDialogLoading = false;
    bool showDialogPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                currentStep == 1 ? "Quên mật khẩu" : "Đặt lại mật khẩu mới",
                style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryPink),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentStep == 1) ...[
                      const Text("Nhập Email đã liên kết với tài khoản của bạn để nhận mã xác thực OTP."),
                      const SizedBox(height: 15),
                      TextField(
                        controller: dialogEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Địa chỉ Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Mã hiệu lực đã được gửi tới:\n${dialogEmailController.text}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: dialogOtpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Mã OTP (6 số)",
                          prefixIcon: const Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: dialogNewPassController,
                        obscureText: !showDialogPassword,
                        decoration: InputDecoration(
                          labelText: "Mật khẩu mới",
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showDialogPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showDialogPassword = !showDialogPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                    final email = dialogEmailController.text.trim();
                    if (currentStep == 1) {
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Vui lòng điền email")),
                        );
                        return;
                      }
                      setDialogState(() => isDialogLoading = true);
                      final res = await _authService.requestForgotPassword(email);
                      setDialogState(() => isDialogLoading = false);

                      if (res['success']) {
                        setDialogState(() => currentStep = 2);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'])),
                        );
                      }
                    } else {
                      final otp = dialogOtpController.text.trim();
                      final newPass = dialogNewPassController.text.trim();
                      if (otp.isEmpty || newPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Vui lòng điền đầy đủ mã OTP và mật khẩu mới")),
                        );
                        return;
                      }
                      setDialogState(() => isDialogLoading = true);
                      final res = await _authService.resetPassword(email, otp, newPass);
                      setDialogState(() => isDialogLoading = false);

                      if (res['success']) {
                        if (mounted) Navigator.pop(context);
                        _showSnackBar("Thay đổi mật khẩu thành công!", isError: false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'])),
                        );
                      }
                    }
                  },
                  child: isDialogLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(currentStep == 1 ? "Gửi mã OTP" : "Xác nhận đổi", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
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

              if (!isLogin) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

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

              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: kPrimaryPink, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

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
                onPressed: () => setState(() {
                  isLogin = !isLogin;
                  _emailController.clear();
                }),
                child: Text(isLogin ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}