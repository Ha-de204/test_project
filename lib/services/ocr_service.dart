import 'dart:io';
import 'package:dio/dio.dart';
import 'apiClient.dart';

class OcrService {
  // Sử dụng instance của Dio đã được cấu hình sẵn cho Backend trên Render
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> scanReceipt(File image) async {
    try {
      // 1. Chuẩn bị tên file và dữ liệu gửi đi dưới dạng FormData
      String fileName = image.path.split('/').last;

      // 'image' phải khớp với upload.single('image') trong ocr.routes.js ở backend
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });

      // 2. Gửi request POST đến endpoint /ocr/scan
      // Lưu ý: Đường dẫn "ocr/scan" sẽ được nối vào baseUrl của ApiClient
      final response = await _dio.post(
        "ocr/scan",
        data: formData,
      );

      // 3. Xử lý kết quả trả về từ Backend
      if (response.statusCode == 200) {
        // Dữ liệu bao gồm: amount, title, date, category_name...
        return response.data;
      } else {
        throw Exception("Server trả về lỗi: ${response.statusCode}");
      }
    } on DioException catch (e) {
      // Xử lý lỗi kết nối hoặc lỗi từ server
      print("Lỗi OCR Service: ${e.message}");
      return _getFallbackData();
    } catch (e) {
      print("Lỗi không xác định: $e");
      return _getFallbackData();
    }
  }

  // Dữ liệu dự phòng nếu quá trình scan gặp lỗi
  Map<String, dynamic> _getFallbackData() {
    return {
      "amount": 0,
      "type": "expense",
      "title": "Lỗi quét hóa đơn",
      "note": "Vui lòng kiểm tra kết nối mạng hoặc thử lại.",
      "date": DateTime.now().toIso8601String(),
      "category_name": "Khác",
    };
  }
}