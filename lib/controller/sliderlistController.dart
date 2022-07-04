

import 'package:flutter/cupertino.dart';
import 'package:restro_simplify/models/slider.dart';

class SliderListController with ChangeNotifier {
  List<SliderModel> _slider=[];
  void setSliderList(List<SliderModel> list){
    _slider = list;
    notifyListeners();
  }
 List<SliderModel> get slider => _slider;
}