import 'package:dio/dio.dart';
import 'apiClient.dart';

class TransactionService {
  final Dio _dio = ApiClient.instance;

  // 1. Tạo giao dịch mới
  Future<Map<String, dynamic>> createTransaction({
    required String categoryId,
    required double amount,
    required String type,
    required String date,
    required String title,
    String? note,
  }) async {
    try {
      final response = await _dio.post("transactions/create", data: {
        "category_id": categoryId,
        "amount": amount,
        "type": type,
        "date": date,
        "title": title,
        "note": note ?? "",
      });
      return {"success": true, "data": response.data};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi tạo giao dịch"
      };
    }
  }

  // 2. Lấy toàn bộ danh sách giao dịch
  Future<List<dynamic>> getTransactions() async {
    try {
      final response = await _dio.get("transactions/list");
      return response.data;
    } on DioException catch (e) {
      print("Lỗi lấy danh sách giao dịch: ${e.message}");
      return [];
    }
  }

  // 3. Lấy chi tiết 1 giao dịch
  Future<Map<String, dynamic>?> getTransactionById(String id) async {
    try {
      final response = await _dio.get("transactions/$id");
      return response.data;
    } on DioException catch (e) {
      print("Lỗi lấy chi tiết giao dịch: ${e.message}");
      return null;
    }
  }

  // 4. Cập nhật giao dịch
  Future<Map<String, dynamic>> updateTransaction(
      String id, {
        required String categoryId,
        required double amount,
        required String type,
        required String date,
        required String title,
        String? note,
      }) async {
    try {
      final response = await _dio.put("transactions/$id", data: {
        "category_id": categoryId,
        "amount": amount,
        "type": type,
        "date": date,
        "title": title,
        "note": note ?? "",
      });
      return {"success": true,  "data": response.data};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi cập nhật giao dịch"
      };
    }
  }

  // 5. Xóa giao dịch
  Future<Map<String, dynamic>> deleteTransaction(String id) async {
    try {
      final response = await _dio.delete("transactions/$id");
      return {"success": true, "message": response.data['message']};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi khi xóa giao dịch"
      };
    }
  }
}