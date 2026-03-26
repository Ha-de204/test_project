import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

import '../constants.dart';
import '../services/apiBudget.dart';
import '../services/apiCategory.dart';
import '../services/apiTransaction.dart';
import '../models/category_model.dart';
import '../utils/data_aggregator.dart';
import '../models/monthly_expense_data.dart';

// Màn hình chi tiết
import 'expense_detail_screen.dart';
import 'budget_detail_screen.dart';
import 'charts_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'scan_camera_screen.dart';
import '../widgets/add_transaction_content.dart';

class ExpenseTrackerScreen extends StatefulWidget {

  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  // Services
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  // State Variables
  DateTime _selectedMonthYear = DateTime.now();
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _filterCategoryId;
  DateTime? _filterDate;
  String _selectedType = 'expense';

  List<CategoryModel> _apiCategories = [];
  List<dynamic> _apiTransactions = [];
  Map<String, double> _budgetsMap = {};

  final List<Map<String, dynamic>> categories = [
    {'id': '658123456789012345678001', 'label': 'Mua sắm', 'icon': Icons.shopping_cart_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678002', 'label': 'Đồ ăn', 'icon': Icons.fastfood_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678003', 'label': 'Quần áo', 'icon': Icons.checkroom_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678004', 'label': 'Nhà ở', 'icon': Icons.home_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678005', 'label': 'Sức khỏe', 'icon': Icons.favorite_border.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678006', 'label': 'Học tập', 'icon': Icons.book_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678007', 'label': 'Du lịch', 'icon': Icons.flight_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678008', 'label': 'Giải trí', 'icon': Icons.videogame_asset_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678009', 'label': 'Sửa chữa', 'icon': Icons.build_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678010', 'label': 'Sắc đẹp', 'icon': Icons.spa_outlined.codePoint, 'type': 'expense'},
    {'id': '658123456789012345678011', 'label': 'Điện thoại', 'icon': Icons.phone_android_outlined.codePoint, 'type': 'expense'},
    {'label': 'Cài đặt', 'icon': Icons.settings_outlined.codePoint, 'isSetting': true, 'type': 'expense'},
    {'label': 'Lương', 'icon': Icons.payments_outlined.codePoint, 'type': 'income'},
    {'label': 'Làm thêm', 'icon': Icons.work_outline.codePoint, 'type': 'income'},
    {'label': 'Tiền thưởng', 'icon': Icons.card_giftcard.codePoint, 'type': 'income'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _cleanId(dynamic rawId) {
    if (rawId == null) return "";
    if (rawId is Map && rawId.containsKey('\$oid')) return rawId['\$oid'].toString();
    String idStr = rawId.toString().trim();
    if (idStr.contains("ObjectId(")) {
      final match = RegExp(r"ObjectId\('([a-fA-F0-9]+)'\)").firstMatch(idStr);
      return match?.group(1) ?? idStr;
    }
    return idStr;
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String period = DateFormat('yyyy-MM').format(_selectedMonthYear);
    try {
      // 1. Lấy danh mục trước để đảm bảo có ID so khớp
      final dynamic resultsRaw = await _categoryService.getCategories();

      List<CategoryModel> fetchedCats = [];
      if (resultsRaw is List) {
        fetchedCats = resultsRaw.map((e) => e as CategoryModel).toList();
      }

      if (fetchedCats.isEmpty) {
        debugPrint("Server trống, bắt đầu khởi tạo...");
        await _initializeDefaultCategoriesOnServer();
        final dynamic reloadCats = await _categoryService.getCategories();
        if (reloadCats is List) {
          _apiCategories = reloadCats.map((e) => e as CategoryModel).toList();
        }
      } else {
        _apiCategories = fetchedCats;
      }

      final results = await Future.wait([
        _budgetService.getBudgets(period),
        _transactionService.getTransactions(),
      ]);
      await DataAggregator.refreshData();

      if (mounted) {
        setState(() {
          // 1. Xử lý Giao dịch
          _apiTransactions = results[1] as List<dynamic>;
          debugPrint("Đã tải được ${_apiTransactions.length} giao dịch từ Server");

          // 2. Xử lý Ngân sách
          final budgetList = results[0] as List<dynamic>;
          double tempTotal = 0;
          Map<String, double> tempMap = {};
          for (var b in budgetList) {
            if (b != null) {
              double amount = (b['BudgetAmount'] as num?)?.toDouble() ?? 0.0;
              String catId = b['category_id']?.toString() ?? 'OTHER';
              if (catId == '000000000000000000000000') {
                tempTotal = amount;
                tempMap['TOTAL'] = amount;
              } else {
                tempMap[catId] = amount;
              }
            }
          }
          _budgetsMap = tempMap;
          _budgetsMap['TOTAL'] = tempTotal;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("LỖI TẢI DỮ LIỆU: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeDefaultCategoriesOnServer() async {
    debugPrint("Đang khởi tạo danh mục mặc định lên Server...");
    final dynamic currentRaw = await _categoryService.getCategories();
    List<String> existingNames = [];
    if (currentRaw is List) {
      existingNames = currentRaw.map((e) => (e as CategoryModel).name.toLowerCase()).toList();
    }

    for (var cat in categories) {
      if (cat['isSetting'] == true) continue;

      String label = cat['label'];
      if (existingNames.contains(label.toLowerCase())) {
        debugPrint("Danh mục '$label' đã tồn tại, bỏ qua.");
        continue;
      }

      try {
        await _categoryService.createCategory(
          label,
          cat['icon'] is int ? cat['icon'] : (cat['icon'] as IconData).codePoint,
          cat['type'] ?? 'expense'
        );
      } catch (e) {
        debugPrint("Lỗi khi đẩy danh mục ${cat['label']}: $e");
      }
    }

    final results = await _categoryService.getCategories();
    if (mounted && results is List) {
      setState(() {
        _apiCategories =  results.map((e) => e as CategoryModel).toList();
      });
    }
  }

  double get _totalBudgetAmount {
    if (_budgetsMap.containsKey('TOTAL')) {
      return _budgetsMap['TOTAL']!;
    }
    return _budgetsMap.values.fold(0.0, (sum, value) => sum + value);
  }

  List<dynamic> get _filteredTransactions {
    return _apiTransactions.where((tx) {
      DateTime txDate = DateTime.parse(tx['date']);
      //  Luôn luôn lọc theo Tháng/Năm đã chọn ở Sổ cái
      bool matchesMonth = txDate.year == _selectedMonthYear.year &&
                          txDate.month == _selectedMonthYear.month;
      if (!matchesMonth) return false;
      //  Lọc theo ngày cụ thể (nếu có chọn ở icon Calendar)
      if (_filterDate != null) {
        if (txDate.day != _filterDate!.day ||
            txDate.month != _filterDate!.month ||
            txDate.year != _filterDate!.year) {
          return false;
        }
      }
      //  Lọc theo danh mục (nếu có chọn ở icon Search)
      if (_filterCategoryId != null) {
        final selectedCat = _apiCategories.firstWhere(
              (c) => c.id == _filterCategoryId,
          orElse: () => CategoryModel(id: '', name: '', iconCodePoint: 0, type: ''),
        );

        String txCatId = _cleanId(tx['category_id']);
        String txTitle = (tx['title'] ?? "").toString().toLowerCase().trim();
        String selectedCatName = selectedCat.name.toLowerCase().trim();

        bool isMatchId = txCatId == _filterCategoryId;
        bool isMatchName = selectedCatName.isNotEmpty && txTitle == selectedCatName;

        if (!isMatchId && !isMatchName) {
        return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => b['date'].compareTo(a['date']));
  }

  double get _totalMonthlyExpense {
    return _filteredTransactions.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  }

  double get _currentMonthBudget => _budgetsMap['TOTAL'] ?? 0.0;

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount);
  }

  List<MonthlyExpenseData> _aggregateMonthlyData(){
    //tạo map nhóm theo 'YYYY-mm'
    final Map<String, List<dynamic>> grouped = {};
    for(var tx in _apiTransactions){
      final key = DateFormat('yyyy-MM').format(DateTime.parse(tx['date']));
      if(!grouped.containsKey(key)){
        grouped[key] = [];
      }
      grouped[key]!.add(tx);
    }

    return grouped.entries.map((entry) {
      final parts = entry.key.split('-');
      double totalExpense = 0;
      double totalIncome = 0;

      for (var tx in entry.value) {
        final amount = (tx['amount'] as num).toDouble();
        final type = (tx['type'] ?? 'expense').toString();

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      final balance = totalIncome - totalExpense;

      return MonthlyExpenseData(
        month: int.parse(parts[1]),
        year: int.parse(parts[0]),
        expense: totalExpense,
        income: totalIncome,
        balance: balance,
      );
    }).toList()..sort((a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month));
  }

  // Hàm xử lý khi chọn tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showMainMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Thêm giao dịch"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTransactionSheet();
                },
              ),

              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text("Scan hóa đơn"),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanCameraScreen(),
                    ),
                  ).then((_) => _fetchData());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // hien menu chon danh muc
  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Lọc theo danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.all_inclusive, color: Colors.white, size: 20),
                ),
                title: const Text('Tất cả danh mục'),
                trailing: _filterCategoryId == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () {
                  setState(() => _filterCategoryId = null);
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _apiCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _apiCategories[index];
                    bool isSelected = _filterCategoryId == cat.id;
                    return ListTile(
                      leading: Icon(IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'), color: isSelected ? kPrimaryPink : Colors.grey),
                      title: Text(
                        cat.name,
                        style: TextStyle(
                            color: isSelected ? kPrimaryPink : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () {
                        setState(() => _filterCategoryId = cat.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm hiển thị lịch chọn tháng/năm
  Future<void> _selectMonthYear(BuildContext context) async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonthYear,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('vi'),
      builder: (context, child) {
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

    if (picked != null && picked != _selectedMonthYear) {
      setState(() {
        _selectedMonthYear = picked;
        _filterDate = null;
        _filterCategoryId = null;
      });
      await _fetchData();
    }
  }

  // Hàm hiển thị lịch chọn ngày cụ thể (cho AppBar)
  Future<void> _selectSpecificDate(BuildContext context) async {
    final firstDayOfMonth = DateTime(_selectedMonthYear.year, _selectedMonthYear.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonthYear.year, _selectedMonthYear.month + 1, 0);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? firstDayOfMonth,
      firstDate: firstDayOfMonth,
      lastDate: lastDayOfMonth,
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryPink,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterDate = picked;
        print('Ngày cụ thể đã chọn để lọc: $_filterDate');
      });
    }
  }

  // Helper để định dạng tháng
  String _formatMonth(int month) {
    switch (month) {
      case 1: return 'Thg 1'; case 2: return 'Thg 2'; case 3: return 'Thg 3';
      case 4: return 'Thg 4'; case 5: return 'Thg 5'; case 6: return 'Thg 6';
      case 7: return 'Thg 7'; case 8: return 'Thg 8'; case 9: return 'Thg 9';
      case 10: return 'Thg 10'; case 11: return 'Thg 11'; case 12: return 'Thg 12';
      default: return '';
    }
  }

  bool _isSameMonth(dynamic tx) {
    final date = DateTime.parse(tx['date']);
    return date.year == _selectedMonthYear.year &&
        date.month == _selectedMonthYear.month;
  }

  // hàm để thêm danh mục mới vào list categories và budget list
  void _addNewCategory(Map<String, dynamic> newCategoryData) async {
    setState(() => _isLoading = true);
    try {
      // 1. Gọi API Service để lưu danh mục mới vào Database
      final response = await _categoryService.createCategory(
        newCategoryData['label'],
        (newCategoryData['icon'] as IconData).codePoint,
          newCategoryData['type']
      );

      if (response != null) {
        // 2. Sau khi thêm thành công, gọi lại hàm fetch để đồng bộ dữ liệu
        await _fetchData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm danh mục: ${newCategoryData['label']}')),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi thêm danh mục: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thêm danh mục. Vui lòng thử lại.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị giao diện thêm giao dịch
  void _showAddTransactionSheet() async {
    final List<Map<String, dynamic>> mapping = _apiCategories.map<Map<String, dynamic>>((c) => {
      'id': c.id,
      'label': c.name,
      'icon': c.iconCodePoint,
      'type': c.type,
      'isSetting': false,
    }).toList();

    mapping.add({
      'id': 'SETTING',
      'label': 'Cài đặt',
      'icon': Icons.settings_outlined.codePoint,
      'isSetting': true,
    });

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: AddTransactionContent(categories: mapping),
          ),
        );
      },
    );

    if(result == true){
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giao dịch đã được lưu!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // Xoa giao dich
  void _deleteTransaction(String id) async {
    final result = await _transactionService.deleteTransaction(id);
    if (result['success']) {
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa giao dịch thành công')),
      );
    }
  }

  // Xóa / sửa giao dịch
  void _showEditOption(dynamic tx){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Sửa giao dịch'),
                onTap: (){
                  Navigator.pop(context);
                  _showEditTransactionSheet(tx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa giao dịch'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTransaction(tx['_id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTransactionSheet(dynamic tx) async {
    final List<Map<String, dynamic>> mapping = _apiCategories.map<Map<String, dynamic>>((c) => {
      'id': c.id,
      'label': c.name,
      'icon': c.iconCodePoint,
      'isSetting': false,
    }).toList();

    mapping.add({
      'label': 'Cài đặt',
      'icon': Icons.settings_outlined.codePoint,
      'isSetting': true,
    });

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            child: AddTransactionContent(
              transaction: tx,
              isEditing: true,
              categories: mapping,
            ),
          ),
        );
      },
    );

    if (result == true) {
      await _fetchData();
    }
  }

  //Widget xây dựng thêm 1 item giao dịch
  Widget _buildTransactionItem(dynamic tx){

    DateTime txDate = DateTime.parse(tx['date']);
    final String txCategoryId = (tx['category_id'] ?? tx['categoryId'] ?? "").toString();
    final String txTitle = (tx['title'] ?? "").toString();

    print("TX ID: $txCategoryId --- CAT IDs: ${_apiCategories.map((e) => e.id).toList()}");

    final category = _apiCategories.firstWhere(
          (c) => c.id == txCategoryId,
      orElse: () => _apiCategories.firstWhere(
            (c) => c.name == txTitle,
        orElse: () => CategoryModel(
            id: '',
            name: txTitle.isNotEmpty ? txTitle : 'Khác',
            iconCodePoint: 58248,
            type: ''
        ),
      ),
    );

    final day = txDate.day;
    final month = txDate.month;
    final weekdayIndex = txDate.weekday;
    final weekdayName = weekdayIndex == 7 ? 'Chủ nhật' : 'Thứ ${weekdayIndex + 1}';
    final formattedDateLine = '$day thg $month, $weekdayName';

    final String displayNote = (tx['note'] != null && tx['note'].toString().isNotEmpty)
        ? tx['note']
        : category.name;

    final bool isIncome = tx['type'] == 'income';

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );

    final formattedAmount = formatter.format(tx['amount']);
    final int iconCode = category.iconCodePoint is int
        ? category.iconCodePoint
        : int.tryParse(category.iconCodePoint.toString()) ?? 58248;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formattedDateLine, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(
                isIncome ? 'Thu nhập: $formattedAmount' : 'Chi tiêu: $formattedAmount',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            ],
          ),
        ),

        InkWell(
          onLongPress: () => _showEditOption(tx),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: kPrimaryPink.withOpacity(0.1),
              child: Icon(
                  IconData(
                    category.iconCodePoint is int
                        ? category.iconCodePoint
                        : int.tryParse(category.iconCodePoint.toString()) ?? 58248,
                    fontFamily: 'MaterialIcons',
                  ),
                  color: kPrimaryPink
              ),
            ),
            title: Text(displayNote, style: const TextStyle(fontSize: 16)),
            trailing: Text(
              '${isIncome ? '+' : '-'}$formattedAmount',
              style: TextStyle(
                fontSize: 16,
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, BuildContext context) {
    Widget? destinationScreen;

    if (label == 'Chi tiêu') {
      destinationScreen = ExpenseDetailScreen(monthlyData: _aggregateMonthlyData());
    } else if (label == 'Ngân sách') {
      String period = DateFormat('yyyy-MM').format(_selectedMonthYear);
      destinationScreen = BudgetDetailScreen(period: period);
    }

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );

    if (destinationScreen == null) {
      return content;
    }

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationScreen!),
        );
        _fetchData();
      },
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: content,
    );
  }

  // Widget helper để tạo item trong Bottom Navigation Bar
  Widget _buildNavItem(IconData icon, String label, int index) {
    final Color color = index == _selectedIndex ? kPrimaryPink : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    final transactionsToDisplay = _filteredTransactions;

    final double budget = _currentMonthBudget;
    final double incomeValue = _apiTransactions
        .where((tx) =>
    (tx['type'] ?? 'expense') == 'income' &&
        _isSameMonth(tx))
        .fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0));

    final double expenseValue = _apiTransactions
        .where((tx) =>
    (tx['type'] ?? 'expense') == 'expense' &&
        _isSameMonth(tx))
        .fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0));

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    final formattedBudget = formatter.format(budget);
    final formattedIncome = formatter.format(incomeValue);
    final formattedExpense = formatter.format(expenseValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  InkWell(
                    onTap: () => _selectMonthYear(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedMonthYear.year}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _formatMonth(_selectedMonthYear.month),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      _buildStatColumn('Chi tiêu', formatter.format(expenseValue), context),
                      const SizedBox(width: 18),
                      _buildStatColumn('Thu nhập', formattedIncome, context),
                      const SizedBox(width: 18),
                      _buildStatColumn('Ngân sách', formattedBudget, context),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1, color: Colors.grey),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: kLightPinkBackground,
            child: transactionsToDisplay.isEmpty
                ? Center(
                  child: Text(
                    _filterCategoryId != null || _filterDate != null
                        ? 'Không tìm thấy giao dịch phù hợp với bộ lọc'
                        : 'Chưa có giao dịch trong tháng ${_selectedMonthYear.month}!',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: transactionsToDisplay.length,
              itemBuilder: (context, index) {
                final tx = transactionsToDisplay[index];
                final originalIndex = _apiTransactions.indexOf(tx);
                return _buildTransactionItem(tx);
              },
            ),

          ),
        ),
      ],
    );
  }

  // 4. Build Function
  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    PreferredSizeWidget? currentAppBar;

    if (_selectedIndex == 0) {
      currentBody = _buildHomeBody(context);
      currentAppBar = AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Sổ cái thu chi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: _showMainMenu,
        ),
        actions: <Widget>[
          if (_filterDate != null || _filterCategoryId != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.red),
              onPressed: () {
                setState(() {
                  _filterDate = null;
                  _filterCategoryId = null;
                });
              },
            ),
          IconButton(
            icon:  Icon(Icons.search, color: _filterCategoryId != null ? kPrimaryPink : Colors.black),
            onPressed: _showCategoryFilter,
          ),
          IconButton(
            icon:  Icon(Icons.calendar_month, color: _filterDate != null ? kPrimaryPink : Colors.black),
            onPressed: () => _selectSpecificDate(context),
          ),
        ],
      );
    } else if (_selectedIndex == 1) {
      currentBody =  const ChartsScreen();
      currentAppBar = null;
    } else if (_selectedIndex == 2) {
      currentBody = ReportsScreen(
        transactions: _apiTransactions,
        budgetsMap: {
          'TOTAL': _totalBudgetAmount,
        },
      );
      currentAppBar = AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Báo cáo', style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.calendar_month, color: Colors.black), onPressed: () => _selectSpecificDate(context)),
        ],
      );
    } else {
      currentBody = const ProfileScreen();
      currentAppBar = AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        actions: const [],
      );
    }

    return Scaffold(
      appBar: currentAppBar,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryPink))
          : currentBody,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: kPrimaryPink,
        shape: const CircleBorder(),
        elevation: 4.0,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavItem(Icons.description_outlined, 'Trang chủ', 0),
              _buildNavItem(Icons.pie_chart_outline, 'Biểu đồ', 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.assignment_outlined, 'Báo cáo', 2),
              _buildNavItem(Icons.person_outline, 'Tôi', 3),
            ],
          ),
        ),
      ),
    );
  }
}