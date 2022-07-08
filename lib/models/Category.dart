// ignore_for_file: file_names

class Category {
  String id;
  String name;
  String? image;
  int? totalProduct;

  Category(
      {required this.id,
      required this.name,
      required this.image,
      required this.totalProduct});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        id: json['id'],
        name: json['name'],
        image: json['image'],
        totalProduct: json["total_products"]);
  }
}
