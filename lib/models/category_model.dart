class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['label']?.toString()
          ?? json['name']?.toString()
          ?? 'Không tên',
      iconCodePoint: json['icon'] is int
          ? json['icon']
          : int.tryParse(json['icon']?.toString() ?? '') ?? 58164,
      type: json['type']?.toString() ?? 'expense',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconCodePoint': iconCodePoint,
      'type': type,
    };
  }
}