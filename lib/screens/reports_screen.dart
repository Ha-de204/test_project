import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/apiReport.dart';
import '../models/report_model.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'dart:math';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _service = ReportService();
  DateTime selectedMonth = DateTime.now();
  ReportSummaryModel? summary;
  List<MonthlyFlowModel> monthlyFlow = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    setState(() {
      isLoading = true;
    });

    final startDate = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final endDate = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    );

    final summaryData = await _service.getSummary(
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    );

    final flowData = await _service.getMonthlyFlow(
      selectedMonth.year,
    );

    setState(() {
      summary = summaryData;
      monthlyFlow = flowData;
      isLoading = false;
    });
  }

  String formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(value);
  }

  Widget buildLegend(Color color, String text) {

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final currentDate = DateTime.now();

    final lastMonth = selectedMonth.year == currentDate.year
        ? currentDate.month
        : 12;

    final values = [
      ...monthlyFlow.map((e) => e.expense),
      ...monthlyFlow.map((e) => e.income),
      ...monthlyFlow.map((e) => e.budget),
    ];

    final maxValue = values.reduce(max);

    final maxY = ((maxValue / 1000000).ceil() + 1) * 1000000.0;

    // Chỉ lấy các tháng đã có ngân sách
    final budgetMonths =
    monthlyFlow.where((e) => e.budget > 0).toList();

// Các tháng vượt ngân sách
    final overBudgetMonths = budgetMonths
        .where((e) => e.expense > e.budget)
        .toList();

// Tổng tiền vượt
    final totalExceeded = overBudgetMonths.fold<double>(
      0,
          (sum, e) => sum + (e.expense - e.budget),
    );

// Tỷ lệ tháng vượt
    final overRate = budgetMonths.isEmpty
        ? 0
        : overBudgetMonths.length / budgetMonths.length;

// Mức sử dụng ngân sách trung bình
    final totalExpense = budgetMonths.fold<double>(
      0,
          (sum, e) => sum + e.expense,
    );

    final totalBudget = budgetMonths.fold<double>(
      0,
          (sum, e) => sum + e.budget,
    );

    final averageUsage =
    totalBudget == 0 ? 0 : totalExpense / totalBudget;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // filter
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_outlined,
                        size: 20,
                      ),

                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MM/yyyy').format(selectedMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () async {

                      final picked = await showMonthYearPicker(
                        context: context,
                        initialDate: selectedMonth,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                        locale: const Locale('vi'),

                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.95,
                            child: Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFFF5C8A),
                                  onPrimary: Colors.white,
                                ),
                              ),

                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  textScaleFactor: 0.96,
                                ),

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 16,
                                  ),

                                  child: child!,
                                ),
                              ),
                            ),
                          );
                        },
                      );

                      if (picked != null) {

                        setState(() {

                          selectedMonth = picked;
                        });

                        loadData();
                      }
                    },

                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // card
            Row(
              children: [
                Expanded(
                  child: buildCard(
                    title: "Tổng chi tiêu",
                    value: summary!.totalExpense,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: buildCard(
                    title: "Tổng thu nhập",
                    value: summary!.totalIncome,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // line chart
            Container(
              height: 340,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xu hướng thu nhập & chi tiêu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // LEGEND
                  Row(
                    children: [
                      buildLegend(
                        Colors.red,
                        'Chi tiêu',
                      ),

                      const SizedBox(width: 20),
                      buildLegend(
                        Colors.green,
                        'Thu nhập',
                      ),

                      const SizedBox(width: 20),
                      buildLegend(
                        Colors.yellow,
                        'Ngân sách'
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),


                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: lastMonth.toDouble(),

                        minY: 0,
                        maxY: maxY,

                        extraLinesData: ExtraLinesData(
                          verticalLines: [
                            VerticalLine(
                              x: selectedMonth.month.toDouble(),
                              color: const Color(0xFF2196F3),
                              strokeWidth: 2,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),

                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),

                        borderData: FlBorderData(
                          show: false,
                        ),

                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 55,
                              interval: 1000000,

                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 1 || value > lastMonth) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'T${value.toInt()}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                              maxContentWidth: 180,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {

                                String label;

                                switch (spot.barIndex) {
                                  case 0:
                                    label = "Chi tiêu";
                                    break;
                                  case 1:
                                    label = "Thu nhập";
                                    break;
                                  case 2:
                                    label = "Ngân sách";
                                    break;
                                  default:
                                    label = "";
                                }

                                return LineTooltipItem(
                                  "$label: ${NumberFormat.compactCurrency(
                                    locale: 'vi_VN',
                                    symbol: 'đ',
                                  ).format(spot.y)}",
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),

                        lineBarsData: [

                          // EXPENSE
                          LineChartBarData(
                            spots: monthlyFlow
                              .where((e) => e.month <= lastMonth)
                              .map((e) {
                              return FlSpot(
                                e.month.toDouble(),
                                e.expense,
                              );
                            }).toList(),
                            isCurved: false,
                            color: Colors.red,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final data = monthlyFlow[index];

                                final isOverBudget =
                                    data.budget > 0 && data.expense > data.budget;

                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: isOverBudget
                                      ? Colors.black
                                      : Colors.red,
                                  strokeWidth: 0.1,
                                  strokeColor: Colors.red,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withOpacity(0.1),
                            ),
                          ),

                          // INCOME
                          LineChartBarData(
                            spots: monthlyFlow
                              .where((e) => e.month <= lastMonth)
                              .map((e) {
                              return FlSpot(
                                e.month.toDouble(),
                                e.income,
                              );
                            }).toList(),
                            isCurved: false,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                            ),

                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.1),
                            ),
                          ),

                          // BUDGET
                          LineChartBarData(
                            spots: monthlyFlow
                              .where((e) => e.month <= lastMonth)
                              .map((e) {
                              return FlSpot(
                                e.month.toDouble(),
                                e.budget,
                              );
                            }).toList(),
                            isCurved: false,
                            color: Colors.yellow,
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Insight
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "📊 Phân tích biểu đồ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 1. Tháng vượt ngân sách
                  if (overBudgetMonths.isEmpty)
                    const Text("✅ Không có tháng nào vượt ngân sách.")
                  else ...[
                    Text(
                      "⚠ Có ${overBudgetMonths.length}/${budgetMonths.length} tháng vượt ngân sách.",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    ...overBudgetMonths.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "• Tháng ${e.month}: vượt ${NumberFormat.compactCurrency(
                            locale: 'vi_VN',
                            symbol: 'đ',
                          ).format(e.expense - e.budget)} so với ngân sách",
                        ),
                      );
                    }),
                  ],

                  const Divider(height: 28),

                  /// 2. Tổng vượt
                  Text(
                    "💸 Tổng tiền vượt ngân sách: "
                        "${NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ').format(totalExceeded)}",
                  ),

                  const SizedBox(height: 10),

                  /// 3. Tỷ lệ
                  Text(
                    "📈 Tỷ lệ tháng vượt ngân sách: "
                        "${(overRate * 100).toStringAsFixed(1)}%",
                  ),

                  const SizedBox(height: 10),

                  /// 4. Mức sử dụng
                  Text(
                    "📊 Mức sử dụng ngân sách trung bình: "
                        "${(averageUsage * 100).toStringAsFixed(1)}%",
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            formatMoney(value),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}