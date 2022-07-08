import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restro_simplify/screens/slider.dart';

class Globals {
  static Timer? timer;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static checkTime(BuildContext context) {
    try {
      final timeValue = Provider.of<TimeController>(context, listen: false);
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        print(timer.tick);
        if (timer.tick > timeValue.timeValue) {
          timer.cancel();
          navigatorKey.currentState!.push(
              MaterialPageRoute(builder: ((context) => const MySlider())));
        }
      });
    } catch (error) {
      print('error');
    }
  }
}

class TimeController with ChangeNotifier {
  int? _timeValue;
  set timeValue(int val) {
    _timeValue = val;
  }

  int get timeValue => _timeValue!;
}
