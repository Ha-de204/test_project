import 'package:dio/dio.dart';
import 'apiClient.dart';
import '../models/report_model.dart';

class ReportService {
  final Dio _dio = ApiClient.instance;

  // 1. Lấy tổng quan
  Future<ReportSummaryModel> getSummary(String startDate, String endDate,) async {
    final response = await _dio.get(
      "reports/summary",
      queryParameters: {
        "startDate": startDate,
        "endDate": endDate,
      },
    );
    return ReportSummaryModel.fromJson(response.data);
  }

  // 2. Lấy dữ liệu biểu đồ tròn
  Future<List<dynamic>> getCategoryBreakdown(String startDate, String endDate) async {
    try {
      final response = await _dio.get(
        "reports/category-breakdown",
        queryParameters: {
          "startDate": startDate,
          "endDate": endDate,
        },
      );
      return response.data;
    } on DioException catch (e) {
      print("Lỗi lấy phân tích danh mục: ${e.message}");
      return [];
    }
  }

  Future<List<MonthlyFlowModel>> getMonthlyFlow(int year) async {
    final response = await _dio.get(
      "reports/monthly-flow",
      queryParameters: {
        "year": year,
      },
    );
    return (response.data as List)
        .map((e) => MonthlyFlowModel.fromJson(e))
        .toList();
  }
}