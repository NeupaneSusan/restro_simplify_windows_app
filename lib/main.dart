import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/screens/loginscreen.dart';
import 'controller/CartController.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => CartController(), child: MyWidget()));
}

class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      navigatorKey: Globals.navigatorKey,
      title: "RestroMS",
      debugShowCheckedModeBanner: false,
      home: const ContainerPage(),
    );
  }
}

class ContainerPage extends StatefulWidget {
  const ContainerPage({Key? key}) : super(key: key);

  @override
  State<ContainerPage> createState() => _ContainerPageState();
}

class _ContainerPageState extends State<ContainerPage> {
  @override
  void initState() {
    super.initState();
    Globals.timer?.cancel();
    Globals.checkTime(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerCancel: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          onPointerDown: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          onPointerHover: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          onPointerMove: (event) {
            Globals.timer?.cancel();
            Globals.checkTime(context);
          },
          child: const LoginScreen()),
    );
  }
}


//  void Function(PointerDownEvent)? onPointerDown,
//   void Function(PointerMoveEvent)? onPointerMove,
//   void Function(PointerUpEvent)? onPointerUp,
//   void Function(PointerHoverEvent)? onPointerHover,
//   void Function(PointerCancelEvent)? onPointerCancel,
//   void Function(PointerSignalEvent)? onPointerSignal,