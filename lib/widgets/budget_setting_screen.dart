import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/apiBudget.dart';
import '../services/apiCategory.dart';
import '../models/category_model.dart';
import '../constants.dart';
import '../utils/data_aggregator.dart';

class BudgetSettingScreen extends StatefulWidget {
  final DateTime selectedMonthYear;
  const BudgetSettingScreen({
    super.key,
    required this.selectedMonthYear,
  });

  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  Map<String, double> _budgetMap = {};
  bool _isLoading = true;

  String? _editingCategoryId;
  String? _editingCategoryName;
  double _currentBudgetInput = 0.0;
  String _inputString = '';

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  String _cleanId(dynamic rawId) {
    if (rawId == null) return "";
    String idStr = rawId.toString();

    if (idStr.contains("ObjectId(")) {
      final match = RegExp(r"ObjectId\('([a-fA-F0-9]+)'\)").firstMatch(idStr);
      return match?.group(1) ?? idStr;
    }

    if (rawId is Map && rawId.containsKey('\$oid')) {
      return rawId['\$oid'].toString();
    }

    return idStr.replaceAll(RegExp(r"[^a-fA-F0-9]"), "").trim();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    String period = DateFormat('yyyy-MM').format(widget.selectedMonthYear);

    try{
      final results = await Future.wait([
        _categoryService.getCategories(),
        _budgetService.getBudgets(period),
      ]);

      setState(() {
        _categories = results[0] as List<CategoryModel>;
        final budgetList = results[1] as List<dynamic>;

        // map data tu server
        Map<String, double> tempMap = {};
        for (var b in budgetList) {
          String bId = _cleanId(b['category_id']);
          double bAmount = (b['BudgetAmount'] as num? ?? 0.0).toDouble();

          if (bId == '000000000000000000000000') {
            tempMap['TOTAL'] = bAmount;
          } else {
            tempMap[bId] = bAmount;
          }
        }
        _budgetMap = tempMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải dữ liệu setting: $e");
    }
  }

  // -Logic Chỉnh sửa
  void _startEditing(String id, String name, double initialBudget) {
    setState(() {
      _editingCategoryId = id;
      _editingCategoryName = name;
      _inputString = initialBudget.toInt().toString();
      _currentBudgetInput = initialBudget;
    });
  }

  void _onKeyTap(String key) {
    if(_editingCategoryId == null) return;

    setState(() {
      if(key == '✓'){
         _budgetMap[_editingCategoryId!] = double.tryParse(_inputString) ?? 0.0;
         _editingCategoryId = null;
         _editingCategoryName = null;
         _inputString = '';
         _currentBudgetInput = 0.0;
         return;
      }

      if(key == 'x'){
        if(_inputString.isNotEmpty){
          _inputString = _inputString.substring(0, _inputString.length-1);
        }
        if(_inputString.isEmpty){
          _inputString = '0';
        }
      } else if (key == '🗑️'){
        _inputString = '0';
      } else if(key == '▼'){
        _editingCategoryName = null;
        _inputString = '';
        _currentBudgetInput = 0.0;
        return;
      } else if(int.tryParse(key) != null){
        if(_inputString.length < 10){
          if(_inputString == '0'){
            _inputString = key;
          } else {
            _inputString += key;
          }
        }
      }
      String cleanInput = _inputString.replaceAll('.', '');
      _currentBudgetInput = double.tryParse(_inputString) ?? 0.0;
    });
  }

  Future<void> _saveAllAndClose() async {
      setState(() => _isLoading = true);
      String period = DateFormat('yyyy-MM').format(widget.selectedMonthYear);

      try{
        List<Future> saveTasks = [];
        for(var entry in _budgetMap.entries) {
          String finalId = entry.key == 'TOTAL'
              ? '000000000000000000000000'
              : entry.key;

          saveTasks.add(_budgetService.upsertBudget(
            categoryId: finalId,
            amount: entry.value,
            period: period,
          ));
        }
        await Future.wait(saveTasks);
        await DataAggregator.refreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu cài đặt ngân sách thành công!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi lưu ngân sách")));
      }
  }

  Widget _buildKey(String label, {bool isAction = false}) {
    bool isCheck = label == '✓';
    bool isDelete = label == '🗑️';
    bool isBackspace = label == 'x';
    bool isDownArrow = label == '▼';

    IconData? icon;
    if (isCheck) icon = Icons.check;
    else if (isDelete) icon = Icons.delete_outline;
    else if (isBackspace) icon = Icons.backspace_outlined;
    else if (isDownArrow) icon = Icons.keyboard_arrow_down;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () => _onKeyTap(label),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAction ? Colors.pink.shade400 : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: isCheck ? null : [
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
                    color: isAction ? Colors.white : Colors.black,
                  ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorKeypad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
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

  Widget _buildBudgetSettingRow(CategoryModel item) {
    bool isEditing = _editingCategoryId == item.id;
    double budgetValue = _budgetMap[item.id] ?? 0.0;
    double displayAmount = isEditing ? _currentBudgetInput : budgetValue;
    Widget editWidget = InkWell(
      onTap: () => _startEditing(item.id, item.name, budgetValue),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          budgetValue == 0.0 ? 'Sửa' : _formatAmount(displayAmount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isEditing ? Colors.pink.shade400 : Colors.black,
          ),
        ),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                  IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: kPrimaryPink,
                  size: 24
              ),
              const SizedBox(width: 15),
              Text(item.name, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              editWidget,
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }

  Widget _buildInputDisplay() {
    String title = _editingCategoryId == 'TOTAL'
      ? 'Ngân sách hàng tháng'
      : (_editingCategoryName ?? '');

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
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
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              _formatAmount(_currentBudgetInput),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  //  BUILD chính
  @override
  Widget build(BuildContext context) {
    bool isEditing = _editingCategoryId != null;

    return Container(
      height: MediaQuery.of(context).size.height * (isEditing ? 0.9 : 0.7),
      padding: const EdgeInsets.only(top: 10),
      child: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.pink))
        : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.black)),
                ),
                const Text('Cài đặt ngân sách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: _saveAllAndClose,
                  child: const Text('Xong', style: TextStyle(color: Colors.pink)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // danh sách ngân sách
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildBudgetSettingRow(CategoryModel(id: 'TOTAL', name: 'Ngân sách hàng tháng', iconCodePoint: 58164, type:'expense')),
                  ..._categories
                      .where((cat) => _cleanId(cat.id) != '000000000000000000000000')
                      .map((item) => _buildBudgetSettingRow(item))
                      .toList(),
                ],
              ),
            ),
          ),

          if (isEditing)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputDisplay(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: SizedBox(
                    height: 250,
                    child: _buildCalculatorKeypad(),
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }
}