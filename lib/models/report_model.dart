class ReportSummaryModel {

  final double totalExpense;
  final double totalIncome;
  final double netBalance;

  ReportSummaryModel({
    required this.totalExpense,
    required this.totalIncome,
    required this.netBalance
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {

    return ReportSummaryModel(
      totalExpense: (json['TotalExpense'] ?? 0).toDouble(),
      totalIncome: (json['TotalIncome'] ?? 0).toDouble(),
      netBalance: (json['NetBalance'] ?? 0).toDouble(),
    );
  }
}

class MonthlyFlowModel {

  final int month;
  final double expense;
  final double income;
  final double balance;
  final double budget;


  MonthlyFlowModel({
    required this.month,
    required this.expense,
    required this.income,
    required this.balance,
    required this.budget

  });

  factory MonthlyFlowModel.fromJson(Map<String, dynamic> json) {

    return MonthlyFlowModel(
      month: json['month'],
      expense: (json['expense'] ?? 0).toDouble(),
      income: (json['income'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      budget: (json['budget'] ?? 0).toDouble(),
    );
  }
}