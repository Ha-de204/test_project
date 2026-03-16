import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:intl/intl.dart';
import '../models/monthly_expense_data.dart';


class ExpenseDetailScreen extends StatefulWidget {
  final List<MonthlyExpenseData> monthlyData;
  const ExpenseDetailScreen({
    super.key,
    required this.monthlyData,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen>{
  DateTime _selectedYear = DateTime.now();

  //định dạng tiền
  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // tính tổng chi tiêu / số dư / thu nhập
  double get _totalExpense{
    final dataForYear = widget.monthlyData.where((data) => data.year == _selectedYear.year).toList();
    return dataForYear.fold(0.0, (sum, item) => sum + item.expense);
  }
  double get _totalBalance{
    final dataForYear = widget.monthlyData.where((data) => data.year == _selectedYear.year).toList();
    return dataForYear.fold(0.0, (sum, item) => sum + item.balance);
  }

  double get _totalIncome{
    final dataForYear = widget.monthlyData.where((data) => data.year == _selectedYear.year).toList();
    return dataForYear.fold(0.0, (sum, item) => sum + item.income);
  }

  // select year
  Future<void> _selectYear(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Chọn năm"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
              initialDate: _selectedYear,
              selectedDate: _selectedYear,
              onChanged: (DateTime dateTime) {
                setState(() {
                  _selectedYear = dateTime;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyRow(MonthlyExpenseData data){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Row(
            children: [
              //cột time
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thg ${data.month}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${data.year}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              //cột chi tiêu
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatAmount(data.expense),
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatAmount(data.income),
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                ),
              ),

              //cột số dư
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatAmount(data.balance),
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context){
    final dataToDisplay = widget.monthlyData.where((data) => data.year == _selectedYear.year).toList()..sort((a, b) => b.month.compareTo(a.month));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tổng quan', style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _selectYear(context),
            child: Row(
              children: [
                Text(
                  '${_selectedYear.year}',
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Tổng chi tiêu', style: TextStyle(fontSize: 16,  fontWeight: FontWeight.bold, color: Colors.black)),
                        SizedBox(
                          height: 25,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatAmount(_totalExpense),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        const Text('Tổng thu nhập', style: TextStyle(fontSize: 16,  fontWeight: FontWeight.bold, color: Colors.black)),
                        SizedBox(
                          height: 25,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatAmount(_totalIncome),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        const Text('Tổng số dư', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black)),
                        SizedBox(
                          height: 25,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatAmount(_totalBalance),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Tháng', style: TextStyle(fontSize: 16,  fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('Chi tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('Thu nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('Số dư', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                  ],
                ),
                const Divider(thickness: 2),
              ],
            ),
          ),

          Expanded(
            child: dataToDisplay.isEmpty
                ? Center(child: Text('Không có dữ liệu chi tiêu trong năm ${_selectedYear.year}'))
                : ListView.builder(
                    itemCount: dataToDisplay.length,
                    itemBuilder: (context, index){
                      return _buildMonthlyRow(dataToDisplay[index]);
                    },
                ),
          ),
        ],
      ),
    );
  }
}

