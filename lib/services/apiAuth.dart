import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiClient.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final Dio _dio = ApiClient.instance;

  // Hàm băm mật khẩu nội bộ
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Gọi hàm registerUser trong Controller
  Future<Map<String, dynamic>> register(String userName, String password) async {
    try {

      final response = await _dio.post("auth/register", data: {
        "userName": userName,
        "password": password,
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
}