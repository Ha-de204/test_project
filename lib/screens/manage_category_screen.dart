import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/apiCategory.dart';
import 'setting_category_screen.dart';

class ManageCategoryScreen extends StatefulWidget {
  const ManageCategoryScreen({super.key});

  @override
  State<ManageCategoryScreen> createState() =>
      _ManageCategoryScreenState();
}

class _ManageCategoryScreenState
    extends State<ManageCategoryScreen> {

  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];

  bool _loading = true;

  String _selectedType = "expense";

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {

    setState(() {
      _loading = true;
    });

    _categories =
    await _categoryService.getCategories();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa danh mục"),
        content: Text(
            "Bạn có chắc muốn xóa '${category.name}'?"
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final result = await _categoryService.deleteCategory(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]),
      ),
    );
    if (result["success"]) {
      _loadCategories();
    }
  }

  List<CategoryModel> get _filteredCategories {

    return _categories.where((e) {

      if(e.isSetting == true){
        return false;
      }

      return e.type == _selectedType;

    }).toList();

  }

  Widget _buildTypeSelector() {

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(

        children: [

          Expanded(
            child: _buildTypeButton(
              "expense",
              "Chi tiêu",
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _buildTypeButton(
              "income",
              "Thu nhập",
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label,) {
    final selected =
        _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.pink
              : Colors.grey.shade200,
          borderRadius:
          BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        title: const Text("Quản lý danh mục"),
        centerTitle: true,
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Column(
        children: [
          _buildTypeSelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: Icon(
                      IconData(
                        category.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                      color: Colors.pink,
                    ),

                    title: Text(category.name),

                    trailing: category.isDefault
                      ? null
                      : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        /// Nút sửa
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: category.canEdit == true
                              ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingCategoryScreen(
                                  category: category,
                                ),
                              ),
                            );

                            _loadCategories();
                          }
                              : null,
                        ),

                        /// Nút xóa
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: category.canDelete == true
                              ? () => _deleteCategory(category)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SettingCategoryScreen(),
            ),
          );

          if (refresh == true) {
            _loadCategories();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Thêm danh mục", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    );

  }
}