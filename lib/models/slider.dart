

import 'dart:typed_data';

class SliderModel {
  String? id;
  String? title;
  Uint8List? image;
  String? description;

  SliderModel({this.id, this.title, this.image, this.description});

  SliderModel.fromJson(Map<String, dynamic> json)  {

    id = json['id'];
    title = json['title'];
    image =  json['image'];
    description = json['description'];
  }

  
  @override
  String toString(){
     return 'SliderModel(id:$id,image:$image)';
  }
}
