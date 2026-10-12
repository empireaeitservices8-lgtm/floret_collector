class BagModel {
  final int id;
  final String size;
  final double price;
  final String description;
  final bool isActive;

  BagModel({
    required this.id,
    required this.size,
    required this.price,
    required this.description,
    required this.isActive,
  });

  factory BagModel.fromJson(Map<String, dynamic> json) {
    return BagModel(
      id: json['id'] as int,
      size: json['size'] as String,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'BagModel(id: $id, size: $size, price: $price, '
        'description: $description, isActive: $isActive)';
  }
}
