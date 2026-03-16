import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/apiCategory.dart';

final Map<String, List<IconData>> iconGroups = {
  'Mua sắm' : [
    Icons.shopping_bag_outlined, Icons.checkroom_outlined, Icons.diamond_outlined,
    Icons.local_mall_outlined, Icons.shopping_cart_outlined, Icons.money_outlined,
    Icons.watch_outlined, Icons.backpack_outlined, Icons.luggage_outlined,
    Icons.dry_cleaning_outlined, Icons.toys_outlined, Icons.store_outlined,
  ],
  'Cuộc sống' : [
    Icons.home_outlined, Icons.local_cafe_outlined, Icons.tv_outlined,
    Icons.bathtub_outlined, Icons.pool_outlined, Icons.umbrella_outlined,
  ],
  'Giải trí' : [
    Icons.videogame_asset_outlined, Icons.movie_outlined, Icons.sports_esports_outlined,
    Icons.music_note_outlined, Icons.camera_alt_outlined, Icons.beach_access_outlined,
    Icons.casino_outlined, Icons.theater_comedy_outlined, Icons.celebration_outlined,
    Icons.headphones_outlined, Icons.pool_outlined, Icons.golf_course_outlined,
  ],
  'Đồ ăn' : [
    Icons.fastfood_outlined, Icons.local_pizza_outlined, Icons.cake_outlined,
    Icons.liquor_outlined, Icons.local_dining_outlined, Icons.lunch_dining_outlined,
    Icons.coffee_outlined, Icons.icecream_outlined, Icons.ramen_dining_outlined,
    Icons.bakery_dining_outlined, Icons.apple_outlined, Icons.local_grocery_store_outlined,
  ],
  'Du lịch' : [
    Icons.flight_outlined, Icons.beach_access_outlined, Icons.directions_boat_outlined,
    Icons.terrain_outlined, Icons.restaurant_menu_outlined, Icons.camera_roll_outlined,
  ],
  'Tài chính' : [
    Icons.account_balance_wallet_outlined, Icons.bar_chart_outlined, Icons.email_outlined,
    Icons.account_balance_outlined, Icons.money_off_csred_outlined, Icons.cases_outlined,
  ],
  'Thể thao' : [
    Icons.sports_football_outlined, Icons.sports_basketball_outlined, Icons.sports_cricket_outlined,
    Icons.sports_golf_outlined, Icons.sports_tennis_outlined, Icons.sports_motorsports_outlined,
    Icons.sports_handball_outlined, Icons.sports_volleyball_outlined, Icons.sports_rugby_outlined,
    Icons.sports_gymnastics_outlined, Icons.sports_hockey_outlined, Icons.sports_kabaddi_outlined,
  ],
  'Giáo dục' : [
    Icons.book_outlined, Icons.school_outlined, Icons.menu_book_outlined,
    Icons.computer_outlined, Icons.science_outlined, Icons.library_books_outlined,
    Icons.draw_outlined, Icons.lightbulb_outline, Icons.mic_outlined,
    Icons.translate_outlined, Icons.mode_edit_outlined, Icons.design_services_outlined,
  ],
  'Sức khỏe' : [
    Icons.favorite_border, Icons.local_hospital_outlined, Icons.spa_outlined,
    Icons.healing_outlined, Icons.fitness_center_outlined, Icons.medical_services_outlined,
    Icons.self_improvement_outlined, Icons.local_pharmacy_outlined, Icons.accessibility_new_outlined,
    Icons.water_drop_outlined, Icons.bed_outlined, Icons.psychology_outlined,
  ],
  'Khác': [
    Icons.settings_outlined, Icons.build_outlined, Icons.phone_android_outlined,
    Icons.home_outlined, Icons.car_repair_outlined, Icons.help_outline,
  ],
};

class SettingCategoryScreen extends StatefulWidget {
  const SettingCategoryScreen({super.key});

  @override
  State<SettingCategoryScreen> createState() => _SettingCategoryScreenState();
}

class _SettingCategoryScreenState extends State<SettingCategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _nameController = TextEditingController();
  IconData? _selectedIcon;
  String _selectedType = "expense";

  @override
  void initState() {
    super.initState();
    _selectedIcon = iconGroups.values.first.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() async {
    final categoryName = _nameController.text.trim();
    if(categoryName.isEmpty || _selectedIcon == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên danh mục và chọn icon.')),
      );
      return;
    }

    try {
      await _categoryService.createCategory(
        categoryName,
        _selectedIcon!.codePoint,
        _selectedType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm danh mục thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Lỗi khi thêm danh mục: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Widget _buildIconItem(IconData icon){
    final isSelected = _selectedIcon == icon;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIcon = icon;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? kPrimaryPink.withOpacity(0.2) : Colors.transparent,
          border: isSelected ? Border.all(color: kPrimaryPink, width: 2) : null,
        ),
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: isSelected ? kPrimaryPink : Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryPink : Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    IconData displayIcon = _selectedIcon ?? iconGroups.values.first.first;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Thêm danh mục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveCategory,
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _buildTypeSelector(),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kPrimaryPink.withOpacity(0.1),
                  child: Icon(displayIcon, color: kPrimaryPink, size: 30),
                ),
                const SizedBox(width: 15),

                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Vui lòng nhập tên danh mục',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((8.0)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, thickness: 0.5, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: iconGroups.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entry.value.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 10.0,
                          crossAxisSpacing: 10.0,
                        ),
                        itemBuilder: (context, index) {
                          return _buildIconItem(entry.value[index]);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}