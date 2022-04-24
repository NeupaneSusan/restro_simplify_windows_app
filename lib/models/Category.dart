// ignore_for_file: file_names

class Category {
  String id;
  String name;
  String? image;
  
  Category({required this.id, required this.name,required this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        id: json['id'],
        name: json['name'],
        image: json['image']
     );
  }
}
