import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrl = "https://api-quan-ly-chi-tieu.onrender.com/api/";
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();

        String? token = prefs.getString('token');

        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $token";
          print("DEBUG: Đã tìm thấy Token và gắn vào Header thành công!");
        } else {
          print("DEBUG: Vẫn không tìm thấy Token trong máy!");
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print("DEBUG: Lỗi 401 - Token không hợp lệ hoặc hết hạn");
        }
        return handler.next(e);
      },
    ));
    return dio;
  }
}