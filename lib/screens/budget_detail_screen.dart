import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/budget_setting_screen.dart';
import 'package:intl/intl.dart';
import '../utils/data_aggregator.dart';
import 'package:month_year_picker/month_year_picker.dart';
import '../services/apiBudget.dart';
import '../services/apiCategory.dart';
import '../services/apiReport.dart';
import '../models/category_model.dart';
import '../utils/notification_service.dart';
import '../models/report_model.dart';

class BudgetCategory {
  final String id;
  final String name;
  double budget;
  final double expense;
  final IconData icon;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.budget,
    required this.expense,
    required this.icon,
  });

  double get remaining => budget - expense;
}

class BudgetDetailScreen extends StatefulWidget {
  final String period;
  const BudgetDetailScreen({super.key, required this.period });

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  // Services
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  final ReportService _reportService = ReportService();

  // state variables
  DateTime _selectedMonthYear = DateTime.now();
  bool _isLoading = true;

  List<CategoryModel> _allCategories = [];
  Map<String, double> _budgetsMap = {};
  Map<String, double> _expensesMap = {};
  double _totalBudgetSetting = 0.0;
  double _totalExpense = 0.0;

  String? _editingCategoryId;
  String _inputString = '';
  double _currentInput = 0.0;

  @override
  void initState(){
    super.initState();
    _loadAllData();
  }

  String _cleanId(dynamic rawId) {
    if (rawId == null) return "";
    if (rawId is Map && rawId.containsKey('\$oid')) {
      return rawId['\$oid'].toString();
    }
    String idStr = rawId.toString().trim();

    if (idStr.contains("ObjectId(")) {
      final match = RegExp(r"ObjectId\('([a-fA-F0-9]+)'\)").firstMatch(idStr);
      return match?.group(1) ?? idStr;
    }

    if (RegExp(r"^[a-fA-F0-9]{24}$").hasMatch(idStr)) {
      return idStr;
    }
    return idStr;
  }

  // tai data tu backend
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    String period = DateFormat('yyyy-MM').format(_selectedMonthYear);
    var nextMonth = DateTime(_selectedMonthYear.year, _selectedMonthYear.month+1, 1);
    DateTime startDateTime = DateTime(_selectedMonthYear.year, _selectedMonthYear.month, 1);
    String startDate = DateFormat('yyyy-MM-dd').format(startDateTime);
    DateTime endDateTime = DateTime(_selectedMonthYear.year, _selectedMonthYear.month + 1, 0);
    String endDate = DateFormat('yyyy-MM-dd').format(endDateTime);

    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _budgetService.getBudgets(period),

      ]);
      setState(() {
        _allCategories = results[0] as List<CategoryModel>;

        // map data ngan sach
        final budgetList = results[1] as List<dynamic>;
        Map<String, double> tempBudgets = {};
        Map<String, double> tempExpenses = {};
        double calculatedTotalExpense = 0.0;

        for (var b in budgetList) {
          if (b == null) continue;

          String bId = _cleanId(b['category_id']);
          double bAmount = (b['BudgetAmount'] as num? ?? 0.0).toDouble();
          double sAmount = (b['TotalSpent'] as num? ?? 0.0).toDouble();

          if (bId != "000000000000000000000000" && bId.isNotEmpty) {
            calculatedTotalExpense += sAmount;

            tempBudgets[bId] = bAmount;
            tempExpenses[bId] = sAmount;

            try {
              final cat = _allCategories.firstWhere((c) => _cleanId(c.id) == bId);
              tempBudgets[cat.name.toLowerCase().trim()] = bAmount;
              tempExpenses[cat.name.toLowerCase().trim()] = sAmount;
            } catch (_) {}
          } else {
            _totalBudgetSetting = bAmount;
          }
        }

        _budgetsMap = tempBudgets;
        _expensesMap = tempExpenses;
        _totalExpense = calculatedTotalExpense;
        _isLoading = false;
      });
      _checkThresholdsAndNotify();
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu ngân sách: $e");
      setState(() => _isLoading = false);
    }
  }

  void _checkThresholdsAndNotify() {
    final items = _displayItems;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

    for (var item in items) {
      if (item.budget > 0) {
        double usagePercent = (item.expense / item.budget) * 100;

        // Kiểm tra ngưỡng 80%
        if (usagePercent >= 80) {
          String message = "";
          if (usagePercent >= 100) {
            message = "Bạn đã chi tiêu vượt mức ngân sách cho ${item.name}!";
          } else {
            message = "Bạn đã dùng hết ${usagePercent.toStringAsFixed(0)}% ngân sách ${item.name}. Còn lại ${currencyFormat.format(item.remaining)}.";
          }

          // Đẩy thông báo ra ngoài thiết bị
          NotificationService().showInstantNotification(
            id: item.id.hashCode,
            title: "Cảnh báo định mức ⚠️",
            body: message,
          );
        }
      }
    }
  }

  // danh sach hien thi da tron data
  List<BudgetCategory> get _displayItems {

    return _allCategories.map((cat) {
      String cleanCatId = _cleanId(cat.id);
      String searchName = cat.name.toLowerCase().trim();

      double budgetValue = _budgetsMap[cleanCatId ] ??
          _budgetsMap[searchName] ??
          0.0;

      double expenseValue = _expensesMap[cleanCatId ] ??
          _expensesMap[searchName] ??
          0.0;

      return BudgetCategory(
        id: cat.id,
        name: cat.name,
        budget: budgetValue,
        expense: expenseValue,
        icon: IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
      );
    }).where((item) => item.budget > 0 || item.expense > 0).toList();
  }

  // logic chế độ sửa trực tiếp
  void _startEditing(String? categoryId, double initialValue) {
    setState(() {
      _editingCategoryId = categoryId ?? 'Monthly';
      _inputString = initialValue.toInt().toString();
      _currentInput = double.tryParse(_inputString) ?? 0.0;
    });
  }

  Future<void> _saveBudget() async {
    if(_editingCategoryId == null) return;
    double newValue = double.tryParse(_inputString) ?? 0.0;
    String period = DateFormat('yyyy-MM').format(_selectedMonthYear);

    setState(() => _isLoading = true);
    String rawId = _editingCategoryId == 'Monthly' ? '000000000000000000000000' : _editingCategoryId!;
    String finalId = _cleanId(rawId);
    try {
      final result = await _budgetService.upsertBudget(
        categoryId: finalId,
        amount: newValue,
        period: period,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await Future.delayed(const Duration(milliseconds: 300));
        await DataAggregator.refreshData();
        await _loadAllData();

        if (mounted) {
          setState(() {
            _editingCategoryId = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ngân sách thành công!')),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Lỗi khi lưu ngân sách: $e");
      }
    }
  }

  void _onKeyTap(String key) {
    if(_editingCategoryId == null) return;

    if(key == '✓'){
      _saveBudget();
      return;
    }

    setState((){
      if(key == 'x'){
        if(_inputString.isNotEmpty){
          _inputString = _inputString.substring(0, _inputString.length-1);
        }
        if(_inputString.isEmpty){
          _inputString = '0';
        }
      } else if (key == '🗑️'){
        _inputString = '0';
        _currentInput = 0.0;
      } else if(key == '▼'){
        _editingCategoryId = null;
        _inputString = '';
        _currentInput = 0.0;
        return;
      } else if(int.tryParse(key) != null){
        if(_inputString.length < 12){
          if(_inputString == '0'){
            _inputString = key;
          } else {
            _inputString += key;
          }
        }
      }
      String cleanInput = _inputString.replaceAll('.', '');
      _currentInput = double.tryParse(_inputString) ?? 0.0;
    });
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount);
  }

  // nut appbar
  Future<void> _selectMonthYear(BuildContext context) async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonthYear,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('vi'),
      builder: (context, child){
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryPink,
              onPrimary: Colors.white,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 0.95,
            ),
            child: child!,
          ),
        );
      },
    );
    if(picked != null && (picked.year != _selectedMonthYear.year || picked.month != _selectedMonthYear.month)){
      setState(() {
        _selectedMonthYear = picked;
      });
      await _loadAllData();
    }
  }

  void _openSettingsScreen() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: BudgetSettingScreen(
              selectedMonthYear: _selectedMonthYear,
            ),
          ),
        );
      },
    );

    if (result == true || result == null) {
      _loadAllData();
    }
  }
  Widget _buildKey(String label, {Color color = Colors.black, bool isAction = false}) {
    bool isCheck = label == '✓';
    bool isDelete = label == '🗑️';
    bool isBackspace = label == 'x';
    bool isDownArrow = label == '▼';
    bool isComma = label == ',';

    IconData? icon;
    if (isCheck) icon = Icons.check;
    else if (isDelete) icon = Icons.delete_outline;
    else if (isBackspace) icon = Icons.backspace_outlined;
    else if (isDownArrow) icon = Icons.keyboard_arrow_down;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () => _onKeyTap(label),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isAction ? Colors.pink.shade400 : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: isAction || isCheck ? null : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: icon != null
              ? Icon(
            icon,
            color: isCheck ? Colors.white : Colors.black,
            size: 24,
          )
              : Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isAction ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDetail(String title, String value, {Color color = Colors.black}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildBudgetRow(String? id, String label, double budget, double expense, {IconData? icon, bool isMonthlyTotal = false}) {
    String currentId = id ?? 'Monthly';
    bool isEditing = _editingCategoryId == currentId;

    double displayBudget = isEditing ? _currentInput : budget;
    double remaining = displayBudget - expense;
    double progress = displayBudget > 0 ? expense / displayBudget : 0.0;

    Color progressColor;
    if (expense > displayBudget) {
      progressColor = Colors.red;
    }
    else if (displayBudget == 0.0 && expense == 0.0) {
      progressColor = Colors.lightGreen.shade200;
    }
    else {
      if (progress <= 0.8) {
        progressColor = Colors.lightGreen;
      } else {
        progressColor = Colors.green.shade200;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 5.0,
                        backgroundColor: Colors.lightGreen.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    if (icon != null)
                      Icon(icon, color: Colors.pink.shade400, size: 30),
                  ],
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMonthlyTotal ? 'Ngân sách hàng tháng' : label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            if (isEditing) {
                              setState(() {
                                _editingCategoryId = null;
                                _inputString = '';
                                _currentInput = 0.0;
                              });
                            } else {
                              _startEditing(currentId, budget);
                            }
                          },
                          child: Text(
                              isEditing ? 'Huỷ' : 'Sửa',
                              style: TextStyle(color: isEditing ? Colors.grey : Colors.pink.shade400)
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatDetail('Ngân sách:', _formatAmount(displayBudget)),
                        _buildStatDetail('Chi tiêu:', _formatAmount(expense), color: Colors.black),
                        _buildStatDetail('Còn lại:', _formatAmount(remaining), color: remaining >= 0 ? Colors.black : Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          if(!isEditing)
            const Divider(
              color: Colors.grey,
              height: 1.0,
              thickness: 0.5,
            ),
        ],
      ),
    );
  }

  Widget _buildInputDisplay() {
    String title = '';
    if (_editingCategoryId == 'Monthly') {
      title = 'Ngân sách hàng tháng';
    } else {
      final category = _allCategories.firstWhere(
            (cat) => cat.id == _editingCategoryId,
        orElse: () => CategoryModel(id: '', name: 'Danh mục', iconCodePoint: 0),
      );
      title = category.name;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            alignment: Alignment.centerRight,
            child: Text(
              _formatAmount(_currentInput),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorKeypad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        const List<String> keys = [
          '7', '8', '9', '▼',
          '4', '5', '6', '🗑️',
          '1', '2', '3', '',
          ',', '0', 'x', '✓',
        ];

        String label = keys[index];
        bool isAction = label == '✓';
        return _buildKey(label, isAction: isAction);
      },
    );
  }

  // BUILD chính
  @override
  Widget build(BuildContext context) {
    bool isEditing = _editingCategoryId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân Sách', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => _selectMonthYear(context),
            child: Row(
              children: [
                Text(
                  'Thg ${DateFormat('MM yyyy').format(_selectedMonthYear)}',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Padding(
              padding: EdgeInsets.only(bottom: isEditing ? 300.0 : 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBudgetRow(
                      null,
                      'Ngân sách hàng tháng',
                      _totalBudgetSetting,
                      _totalExpense,
                      isMonthlyTotal: true
                  ),

                  const SizedBox(height: 20),

                  ..._displayItems.map((item) {
                    return _buildBudgetRow(
                      item.id,
                      item.name,
                      item.budget,
                      item.expense,
                      icon: item.icon,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing)
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInputDisplay(),
                          Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: SizedBox(
                                height: 220,
                                child: _buildCalculatorKeypad(),
                              )
                          )
                        ]
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _openSettingsScreen,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.pink.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '+ Cài đặt ngân sách',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}