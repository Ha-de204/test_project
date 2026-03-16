import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/apiCategory.dart';
import '../services/apiTransaction.dart';

class CategoryExpense {
  final String categoryName;
  final double totalAmount;
  final IconData icon;
  final double percentage;

  CategoryExpense({
    required this.categoryName,
    required this.totalAmount,
    required this.icon,
    required this.percentage,
  });
}

class DataAggregator {
  static List<dynamic> _allTransactions = [];
  static List<CategoryModel> _allCategories = [];
  static const Color defaultPrimaryColor = Color(0xFFE91E63);

  static final TransactionService _transactionService = TransactionService();
  static final CategoryService _categoryService = CategoryService();

  // --- HÀM CẬP NHẬT DỮ LIỆU TỪ API ---
  static Future<void> refreshData() async {
    try {
      final results = await Future.wait([
        _transactionService.getTransactions(),
        _categoryService.getCategories(),
      ]);

      if (results[0] != null) {
        _allTransactions = results[0] as List<dynamic>;
      }

      if (results[1] != null) {
        _allCategories = results[1] as List<CategoryModel>;
      }

      debugPrint("Aggregator: Đã tải ${_allTransactions.length} giao dịch.");
    } catch (e) {
      debugPrint("Lỗi khi đồng bộ dữ liệu Aggregator: $e");
    }
  }

  static List<CategoryExpense> aggregateCategoryExpenses(DateTime date, int filterIndex, String targetType) {
    DateTime startDate;
    DateTime endDate;

    if (filterIndex == 0) {
      startDate = getStartOfWeek(date);
      endDate = getEndOfWeek(date);
    } else if (filterIndex == 1) {
      startDate = getStartOfMonth(date);
      endDate = getEndOfMonth(date);
    } else {
      startDate = getStartOfYear(date);
      endDate = getEndOfYear(date);
    }

    // Lọc giao dịch trong khoảng thời gian
    final filteredTransactions = _allTransactions.where((tx) {
      final DateTime txDate = DateTime.parse(tx['date']);
      final String type = (tx['type'] ?? 'expense').toString().toLowerCase();

      return type == targetType &&
          txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          txDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    return _processExpenses(filteredTransactions, targetType);
  }

  static List<CategoryExpense> _processExpenses(List<dynamic> transactions, String targetType,) {

    final Map<String, double> nameTotals = {};

    for (var tx in transactions) {
      final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final String catId = (tx['category_id'] ?? tx['categoryId'] ?? "").toString();
      final String catNameFromTx = (tx['category_name'] ?? tx['title'] ?? "Khác").toString();
      final String type = (tx['type'] ?? 'expense').toString().toLowerCase();

      final matchedCat = _allCategories.firstWhere(
            (c) => c.id == catId,
        orElse: () => _allCategories.firstWhere(
              (c) => c.name.toLowerCase() == catNameFromTx.toLowerCase(),
          orElse: () => CategoryModel(id: '', name: catNameFromTx, iconCodePoint: 58248, type: targetType),
        ),
      );

      nameTotals.update(
        matchedCat.name,
            (existing) => existing + amount,
        ifAbsent: () => amount,
      );

    }

    final totalAmount = nameTotals.values.fold(0.0, (sum, amt) => sum + amt);
    if (totalAmount == 0.0) return [];

    return nameTotals.entries.map((entry) {
      final categoryInfo = _allCategories.firstWhere(
            (c) => c.name == entry.key,
        orElse: () => CategoryModel(id: '', name: entry.key, iconCodePoint: 58248, type: targetType),
      );

      return CategoryExpense(
        categoryName: entry.key,
        totalAmount: entry.value,
        icon: IconData(categoryInfo.iconCodePoint ?? 58248, fontFamily: 'MaterialIcons'),
        percentage: entry.value / totalAmount,
      );
    }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }

  static DateTime getStartOfWeek(DateTime date){
    int diff = date.weekday - 1;
    if(diff<0) diff += 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  static DateTime getEndOfWeek(DateTime date){
    return getStartOfWeek(date).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }

  // tìm giao dịch sớm nhất
  static DateTime _getFirstTransactionDate() {
    if (_allTransactions.isEmpty) {
      return DateTime.now().subtract(const Duration(days: 365));
    }
    return _allTransactions.fold(DateTime.parse(_allTransactions.first['date']), (minDate, tx) {
      DateTime currentTxDate = DateTime.parse(tx['date']);
      return currentTxDate.isBefore(minDate) ? currentTxDate : minDate;
    });
  }

  // tổng chi tieu / thu nhap
  static double getTotalAmount(DateTime date, int filterIndex, String targetType) {
    final data = aggregateCategoryExpenses(date, filterIndex, targetType);
    return data.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  static double getBalance(DateTime date, int filterIndex) {
    final income =
    getTotalAmount(date, filterIndex, "income");

    final expense =
    getTotalAmount(date, filterIndex, "expense");

    return income - expense;
  }

  // lấy dl cho các chu kỳ trước
  static List<DateTime> getPastPeriods(int selectedFilterIndex, DateTime currentDate) {
    List<DateTime> periods = [];
    DateTime firstTransactionDate = _getFirstTransactionDate();

    // 1. xac dinh ngay bat dau cua chu ky dau tien (chua gd som nhat)
    DateTime startIteratingDate;
    if (selectedFilterIndex == 0) {
      startIteratingDate = getStartOfWeek(firstTransactionDate);
    } else if (selectedFilterIndex == 1) {
      startIteratingDate = getStartOfMonth(firstTransactionDate);
    } else {
      startIteratingDate = getStartOfYear(firstTransactionDate);
    }

    DateTime currentPeriodDate = startIteratingDate;

    // 2. lap den chu ky chua ngay hien tai
    while (true) {
      periods.add(currentPeriodDate);
      DateTime endOfCurrentPeriod;
      if (selectedFilterIndex == 0) {
        endOfCurrentPeriod = getEndOfWeek(currentPeriodDate);
      } else if (selectedFilterIndex == 1) {
        endOfCurrentPeriod = getEndOfMonth(currentPeriodDate);
      } else {
        endOfCurrentPeriod = getEndOfYear(currentPeriodDate);
      }

      if (endOfCurrentPeriod.year == currentDate.year &&
          endOfCurrentPeriod.month == currentDate.month &&
          (selectedFilterIndex == 1 || selectedFilterIndex == 2 || (selectedFilterIndex == 0 && endOfCurrentPeriod.isAfter(currentDate)) )
      ) {
        if (selectedFilterIndex == 1 || selectedFilterIndex == 2) {
          break;
        }
        if (endOfCurrentPeriod.isAfter(currentDate) && currentPeriodDate.isBefore(currentDate)) {
          break;
        }
      }

      // 3. sang chu ky tiep theo
      if (selectedFilterIndex == 0) {
        currentPeriodDate = currentPeriodDate.add(const Duration(days: 7));
      } else if (selectedFilterIndex == 1) {
        currentPeriodDate = DateTime(currentPeriodDate.year, currentPeriodDate.month + 1, 1);
      } else {
        currentPeriodDate = DateTime(currentPeriodDate.year + 1, 1, 1);
      }

      if (periods.length > 500) break;

      if (currentPeriodDate.isAfter(currentDate.add(const Duration(days: 31)))) break;
    }
    return periods;
  }

}
