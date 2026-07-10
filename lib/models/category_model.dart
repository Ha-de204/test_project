class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String type;

  final bool isDefault;
  final bool canEdit;
  final bool canDelete;
  final bool isSetting;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.type,
    this.isDefault = false,
    this.canEdit = true,
    this.canDelete = true,
    this.isSetting = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),

      name: json['label']?.toString() ??
          json['name']?.toString() ??
          'Không tên',

      iconCodePoint: json['icon'] is int
          ? json['icon']
          : int.tryParse(json['icon']?.toString() ?? '') ?? 58164,

      type: json['type']?.toString() ?? 'expense',

      isDefault: json['isDefault'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
      isSetting: json['isSetting'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "iconCodePoint": iconCodePoint,
      "type": type,
    };
  }
}