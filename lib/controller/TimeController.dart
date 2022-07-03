import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restro_simplify/screens/slider.dart';

class Globals {
  static Timer? timer;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static checkTime(BuildContext context) {

    try {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        print(timer.tick);
        if (timer.tick > 5) {
          timer.cancel();
          
         navigatorKey.currentState!.push(MaterialPageRoute(builder: ((context) => const MySlider())));
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const MySlider()),
          // );
        }
      });
    } catch (error) {
      print('error');
    }
  }
}

