import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiClient.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final Dio _dio = ApiClient.instance;

  // Đăng kí
  Future<Map<String, dynamic>> register(String userName, String password, String email) async {
    try {

      final response = await _dio.post("auth/register", data: {
        "userName": userName,
        "password": password,
        "email": email,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        String? token = response.data['token'];
        dynamic userId = response.data['user_id'];

        if (token != null) {
          await prefs.setString('token', token);
          await prefs.setString('user_id', userId.toString());
          await prefs.setString('userName', response.data['userName'] ?? '');
        }

        await prefs.reload();

        print("XÁC NHẬN ĐÃ LƯU: ${prefs.getString('token')}");
        // Đợi một chút để đảm bảo dữ liệu đã được ghi xuống ổ đĩa
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return {"success": true, "data": response.data};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi đăng ký"
      };
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login(String userName, String password) async {
    try {
      final response = await _dio.post("auth/login", data: {
        "userName": userName,
        "password": password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', response.data['token']);
        await prefs.setString('user_id', response.data['user_id'].toString());
        await prefs.setString('userName', response.data['userName'] ?? '');

        await Future.delayed(Duration(milliseconds: 100));

        return {"success": true, "data": response.data};
      }
      return {"success": false, "message": "Phản hồi không xác định"};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Tên đăng nhập hoặc mật khẩu không chính xác"
      };
    }
  }

  // Hàm yc gửi mã OTP quên pw
  Future<Map<String, dynamic>> requestForgotPassword(String email) async {
    try {
      final response = await _dio.post("auth/forgot-password", data: {
        "email": email,
      });

      if (response.statusCode == 200) {
        return {"success": true, "message": response.data['message']};
      }
      return {"success": false, "message": "Không thể gửi yêu cầu."};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi khi yêu cầu cấp OTP"
      };
    }
  }

  // Hàm xác thực OTP & set pw mới
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await _dio.post("auth/reset-password", data: {
        "email": email,
        "otp": otp,
        "newPassword": newPassword,
      });

      if (response.statusCode == 200) {
        return {"success": true, "message": response.data['message']};
      }
      return {"success": false, "message": "Đặt lại mật khẩu thất bại."};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Mã OTP không đúng hoặc hết hạn"
      };
    }
  }
}