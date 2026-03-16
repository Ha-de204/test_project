import 'package:dio/dio.dart';
import 'package:quan_ly_chi_tieu/models/category_model.dart';
import 'apiClient.dart';

class CategoryService {
  final Dio _dio = ApiClient.instance;

  // 1. Lấy danh sách danh mục của người dùng
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get("categories/list");
      print(response.data);

      final data = response.data;
      if (data != null && data is List) {
        return data
            .map((item) => CategoryModel.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print("Lỗi lấy danh mục: ${e.message}");
      return [];
    }
  }

  // 2. Tạo danh mục mới
  Future<Map<String, dynamic>> createCategory(String name, int iconCodePoint, type) async {
    try {
      final response = await _dio.post("categories/create", data: {
        "name": name,
        "iconCodePoint": iconCodePoint,
        "type": type,
      });
      return {"success": true, "data": response.data};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi tạo danh mục"
      };
    }
  }

  // 3. Cập nhật danh mục
  Future<Map<String, dynamic>> updateCategory(String id, String name, int iconCodePoint, type) async {
    try {
      final response = await _dio.put("categories/$id", data: {
        "name": name,
        "iconCodePoint": iconCodePoint,
        "type": type,
      });
      return {"success": true, "message": response.data['message']};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi cập nhật"
      };
    }
  }

  // 4. Xóa danh mục
  Future<Map<String, dynamic>> deleteCategory(String id) async {
    try {
      final response = await _dio.delete("categories/$id");
      return {"success": true, "message": response.data['message']};
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Lỗi xóa danh mục"
      };
    }
  }
}