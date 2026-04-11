import 'dart:io';
import 'package:dio/dio.dart';
import './apiClient.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class OcrService {

  Future<Map<String, dynamic>> scanReceipt(File image) async {

     final Dio dio = ApiClient.instance;
     try {
      String fileName = p.basename(image.path);
      String extension = p.extension(image.path).replaceAll('.', '');

      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          image.path,
          filename:fileName,
          contentType: MediaType('image', extension.isEmpty ? 'jpeg' : extension),
        ),
      });

      final response = await dio.post("ocr/scan",data: formData,);
      if (response.statusCode == 200) {
        print("Scan successful: ${response.data}");
        return response.data as Map<String, dynamic>;
      } else {
        print("Scan failed with status: ${response.statusCode}");
        throw Exception('Failed to scan receipt. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print("Server Error Data: ${e.response?.data}");
      throw Exception('Lỗi server: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      print("An unexpected error occurred: $e");
      throw Exception('An unexpected error occurred');
    }
  }

    // MOCK RESPONSE
   // return {
   //   "amount": 125000,
   //   "type": "expense",
   //   "title": "Highlands Coffee",
   //   "note": "Trà đào",
   //   "date": DateTime.now().toIso8601String(),
   //   "category_name": "Đồ ăn",
   // };
}