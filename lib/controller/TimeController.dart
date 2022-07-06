import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restro_simplify/screens/slider.dart';

class Globals {
  static Timer? timer;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static checkTime(BuildContext context) {
    try {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timer.tick > 1000) {
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
