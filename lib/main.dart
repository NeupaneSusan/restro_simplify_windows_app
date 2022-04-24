import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:restro_simplify/screens/loginscreen.dart';
import 'controller/CartController.dart';


void main() =>  runApp(ChangeNotifierProvider(
      create: (context) => CartController(), child: const MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool? check;
  
  
  
  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return const MaterialApp(
      title: "RestroMS",
      debugShowCheckedModeBanner: false,
    
      home:  LoginScreen(),
    );
  }
}
