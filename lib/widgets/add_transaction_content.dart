import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:math_expressions/math_expressions.dart';
import '../screens/setting_category_screen.dart';
import '../services/apiTransaction.dart';
import '../utils/budget_checker_service.dart';

class AddTransactionContent extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final dynamic transaction;
  final bool isEditing;

  const AddTransactionContent({
    super.key,
    this.transaction,
    this.isEditing = false,
    required this.categories,
  });

  @override
  State<AddTransactionContent> createState() => _AddTransactionContentState();
}

class _AddTransactionContentState extends State<AddTransactionContent> {
  final TransactionService _transactionService = TransactionService();
  int _selectedIndex = -1;
  String _displayValue = '0';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  String _selectedType = 'expense';

  final TextEditingController _noteController = TextEditingController();
  final Map<int, GlobalKey> _categoryKeys = {};

  String get formattedDateShort {
    final day = _selectedDate.day;
    final month = _selectedDate.month;
    final year = _selectedDate.year;
    return '$day thg $month, $year';
  }

  // Hàm lọc danh mục theo Thu nhập hoặc Chi tiêu
  List<Map<String, dynamic>> get _filteredCategories {
    return widget.categories.where((cat) {
      if (cat['isSetting'] == true) return true;

      final type = (cat['type'] ?? 'expense').toString();
      return type == _selectedType;
    }).toList();
  }

  @override
  void initState(){
    super.initState();
    // tải dl khi ở chế độ sửa
    if(widget.isEditing && widget.transaction != null){
      final tx = widget.transaction;

      // 1. Ép kiểu amount an toàn
      double amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      _displayValue = amt % 1 == 0 ? amt.toInt().toString() : amt.toString();

      // 2. Xử lý ngày tháng
      if (tx['date'] != null) {
        _selectedDate = DateTime.parse(tx['date'].toString());
      }

      _noteController.text = tx['note']?.toString() ?? '';

      // 3. Tìm Index của danh mục
      final txCatId = (tx['category_id'] ?? tx['categoryId'])?.toString();

      int foundIndex = widget.categories.indexWhere((cat) {
        final catId =(cat['id'] ?? cat['_id'])?.toString();
        return catId != null && catId == txCatId;
      });

      if (foundIndex == -1) {
        foundIndex = widget.categories.indexWhere(
                (cat) =>  cat['label'].toString().toLowerCase() == tx['category_name'].toString().toLowerCase()
        );
      }

      setState(() {
        _selectedIndex = foundIndex != -1 ? foundIndex : 0;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    if (_needsCalculation()) {
      _onKeyPressed('check');
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (_displayValue == 'Lỗi' || double.tryParse(_displayValue) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ!')));
      setState(() => _isSaving = false);
      return;
    }

    final double amount = double.tryParse(_displayValue) ?? 0.0;
    final selectedCategory = _filteredCategories[_selectedIndex];

    final String categoryId = (selectedCategory['_id'] ?? selectedCategory['id'] ?? "").toString();
    if (categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Danh mục này chưa được cấp ID!'), backgroundColor: Colors.orange),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      Map<String, dynamic> response;
      if (widget.isEditing) {
        // Cập nhật giao dịch hiện có
        response = await _transactionService.updateTransaction(
          widget.transaction['_id'].toString(),
          categoryId: categoryId,
          amount: amount,
          type: _selectedType,
          date: _selectedDate.toIso8601String(),
          title: selectedCategory['label'].toString(),
          note: _noteController.text,
        );
      } else {
        // Tạo giao dịch mới
        response = await _transactionService.createTransaction(
          categoryId: categoryId,
          amount: amount,
          type: _selectedType,
          date: _selectedDate.toIso8601String(),
          title: selectedCategory['label'].toString(),
          note: _noteController.text,
        );
      }

      if (response != null && (response['success'] == true || response['transaction_id'] != null)) {
        debugPrint("Lưu thành công!");
        if (mounted) Navigator.pop(context, true);
      } else {
        String msg = response['message'] ?? 'Server từ chối lưu (có thể thiếu User ID)';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Có lỗi xảy ra')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối đến máy chủ. Hãy thử lại sau!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    await BudgetCheckerService()
        .checkAndNotify(DateTime.now());
  }

  // HÀM HIỂN THỊ DATE PICKER
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  //Logic tính toán
  bool _needsCalculation() {
    return _displayValue.contains('+') ||
        (_displayValue.contains('-') && _displayValue.indexOf('-') > 0) ||
        _displayValue.contains('/');
  }
  bool _isOperator(String char) {
    return char == '+' || char == '-' || char == '/';
  }

  void _handleCategoryTap(Map<String, dynamic> category, int index) async {
    final bool isSetting = category['isSetting'] ?? false;
    final String label = category['label'] as String;

    if (isSetting) {
      final newCategory = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingCategoryScreen(),
        ),
      );

      if (newCategory == true || newCategory == "refresh") {
        if (mounted) {
          Navigator.pop(context, true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Danh mục đã được cập nhật! Vui lòng chọn lại.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

    } else {
      setState(() {
        _selectedIndex = index;
        if (!widget.isEditing) {
          _displayValue = '0';
        }
      });

      final targetKey = _categoryKeys[index];
      if (targetKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scrollable.ensureVisible(
            targetKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            alignment: 0.0,
          );
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chọn: $label')),
      );
    }
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'D') {
        if (_displayValue.length > 1) {
          _displayValue = _displayValue.substring(0, _displayValue.length - 1);
        } else {
          _displayValue = '0';
        }
      } else if (key == 'check') {
        if (_needsCalculation()) {
          try {
            String finalExpression = _displayValue;
            Parser p = Parser();
            Expression exp = p.parse(finalExpression);

            ContextModel cm = ContextModel();
            double eval = exp.evaluate(EvaluationType.REAL, cm);
            String result = eval.toStringAsFixed(2);
            if (result.endsWith('.00')) {
              _displayValue = result.substring(0, result.length - 3);
            } else {
              _displayValue = result;
            }
          } catch (e) {
            _displayValue = 'Lỗi';
          }
        }
      } else if (_isOperator(key)) {
          if (_displayValue.isNotEmpty &&
              !_isOperator(_displayValue.substring(_displayValue.length - 1))) {
            _displayValue += key;
          } else if (_displayValue == '0' && key == '-') {
            _displayValue = key;
          }
      } else {
        if (_displayValue == '0' || _displayValue == 'Lỗi') {
            _displayValue = key;
        } else {
            if (key == '.' && _displayValue.contains('.')) {
              return;
            }
            _displayValue += key;
        }
      }
    });
  }

  Widget _buildCategoryItem(BuildContext context, int index, String label, dynamic iconData, {bool isSetting = false}){
    final bool isSelected = _selectedIndex == index && !isSetting;

    IconData displayIcon;
    if (iconData is IconData) {
      displayIcon = iconData;
    } else if (iconData != null) {
      int? codePoint = int.tryParse(iconData.toString());
      displayIcon = IconData(codePoint ?? 58248, fontFamily: 'MaterialIcons');
    } else {
      displayIcon = Icons.category;
    }

    return InkWell(
      onTap: (){
        _handleCategoryTap(_filteredCategories[index], index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            displayIcon,
            size: 30,
            color: isSelected ? kPrimaryPink : Colors.grey[700]
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 15, color: isSelected ? kPrimaryPink : Colors.black)),
        ],
      ),
    );
  }

  // Helper Widget xây dựng nút bàn phím
  Widget _buildKeyboardButton(String label, {IconData? icon, Color? color, bool isOperation = false, VoidCallback? onTap, bool isCalendarButton = false}) {
    final Color textColor = isOperation ? kPrimaryPink : Colors.black;
    final Color backgroundColor = isOperation && icon == Icons.check ? kPrimaryPink : Colors.white;

    String key = label;
    if (icon == Icons.check) key = 'check';
    if (icon == Icons.backspace_outlined) key = 'D';

      return Padding(
          padding: const EdgeInsets.all(4.0),
          child: InkWell(
            onTap: () {
              print("Đã nhấn phím: ${icon == Icons.check ? 'DẤU TÍCH' : label}");
              if (onTap != null) {
                onTap();
              } else if (icon == Icons.check) {
                if (!_isSaving) {
                  print("Đang gọi hàm _saveTransaction...");
                  _saveTransaction();
                }
              } else {
                _onKeyPressed(label == '' ? (icon == Icons.backspace_outlined ? 'D' : '') : label);
              }
            },
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),

            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (icon == Icons.check) ? kPrimaryPink : Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isSaving && icon == Icons.check
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : (isCalendarButton
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined, color: Colors.black, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        formattedDateShort,
                        style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                  : (icon != null
                  ? Icon(icon, color: icon == Icons.check ? Colors.white : Colors.black, size: 24)
                  : Text(label, style: TextStyle(fontSize: 24, fontWeight: isOperation ? FontWeight.bold : FontWeight.w500, color: textColor)))),
            ),
          ),
        );
  }

  // Widget riêng chứa Ghi chú và bàn phím
  Widget _buildInputAndKeyboard(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                    _displayValue,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.grey[800])
                ),
              ),
              const SizedBox(height: 5),

              //ghi chú
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Ghi chú: Nhập ghi chú...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    hintStyle: TextStyle(color: Colors.grey, fontSize:16),
                  ),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),

        //Bàn phím
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildKeyboardButton('7')),
                        Expanded(child: _buildKeyboardButton('8')),
                        Expanded(child: _buildKeyboardButton('9')),
                        Expanded(child: _buildKeyboardButton('+', isOperation: true)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildKeyboardButton('4')),
                        Expanded(child: _buildKeyboardButton('5')),
                        Expanded(child: _buildKeyboardButton('6')),
                        Expanded(child: _buildKeyboardButton('-', isOperation: true)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildKeyboardButton('1')),
                        Expanded(child: _buildKeyboardButton('2')),
                        Expanded(child: _buildKeyboardButton('3')),
                        Expanded(child: _buildKeyboardButton('/', isOperation: true)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildKeyboardButton('', icon: Icons.calendar_month_outlined, onTap: _selectDate, isCalendarButton: true)),
                        Expanded(child: _buildKeyboardButton('0')),
                        Expanded(child: _buildKeyboardButton('', icon: Icons.backspace_outlined)),
                        Expanded(child: _buildKeyboardButton('', icon: Icons.check, isOperation: true)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton("expense", "Chi tiêu"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTypeButton("income", "Thu nhập"),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    final bool isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedIndex = -1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryPink : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final bool showInputSection = _selectedIndex != -1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.black, fontSize: 18)),
              ),
              Text(
                widget.isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1),

        _buildTypeSelector(),

        // Body cuộn
        Expanded(
          child: GridView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: _filteredCategories.length,
            itemBuilder: (context, index) {
              final categories = _filteredCategories;
              if (!_categoryKeys.containsKey(index)) {
                _categoryKeys[index] = GlobalKey();
              }
              final category = categories[index];

              return KeyedSubtree(
                key: _categoryKeys[index],
                child: _buildCategoryItem(
                  context,
                  index,
                  category['label'] as String,
                  category['icon'],
                  isSetting: category['isSetting'] ?? false,
                ),
              );
            },
          ),
        ),
        if (showInputSection)
          _buildInputAndKeyboard(),
      ],
    );
  }
}