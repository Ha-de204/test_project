import 'package:intl/intl.dart';
import '../services/apiBudget.dart';
import '../services/apiCategory.dart';
import '../utils/notification_service.dart';
import '../models/category_model.dart';

class BudgetCheckerService {
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  Future<void> checkAndNotify(DateTime month) async {
    try {
      String period = DateFormat('yyyy-MM').format(month);

      final categories = await _categoryService.getCategories();
      final budgets = await _budgetService.getBudgets(period);

      final currencyFormat = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'VND',
        decimalDigits: 0,
      );

      for (var b in budgets) {
        double budget = (b['BudgetAmount'] ?? 0).toDouble();
        double spent = (b['TotalSpent'] ?? 0).toDouble();

        if (budget <= 0) continue;

        double percent = spent / budget * 100;
        double remain = budget - spent;

        if (percent >= 80) {
          final cat = categories.cast<CategoryModel?>().firstWhere(
                (c) => c?.id == b['category_id'],
            orElse: () => null,
          );

          final name = cat?.name ?? "Danh mục";

          String message =
          percent >= 100
              ? "Bạn đã chi tiêu vượt mức ngân sách cho $name!"
              : "Bạn đã dùng hết ${percent.toStringAsFixed(0)}% ngân sách $name. Còn lại ${currencyFormat.format(remain)}.";

          NotificationService().showInstantNotification(
            id: name.hashCode,
            title: "Cảnh báo định mức ⚠️",
            body: message,
          );
        }
      }
    } catch (e) {
      print("Budget check error: $e");
    }
  }
}