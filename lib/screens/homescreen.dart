import 'dart:convert';
import 'dart:typed_data';

import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restro_simplify/screens/orderscreen.dart';
import 'package:restro_simplify/screens/paidorders.dart';
import 'package:restro_simplify/screens/pos.dart';
import 'package:restro_simplify/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ignore: prefer_typing_uninitialized_variables
  var userData;
  Uint8List? byte;
  Uint8List bytess = Uint8List.fromList([]);
// get userdata from localstorage
  getUserFromLocalStorage() async {
    try {
      Uint8List? bytes;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var res = await http
          .get(Uri.parse('http://192.168.1.1/restroms/api/qrcodes/fonepay'));
      if (res.statusCode == 200) {
        var jsonData = jsonDecode(res.body)['qrcode'];
        final ByteData imageData =
            await NetworkAssetBundle(Uri.parse(jsonData)).load("");
        bytes = imageData.buffer.asUint8List();
      }
      setState(() {
        userData = json.decode(prefs.getString('user')!);
        byte = bytes;
      });
      if (kDebugMode) {
        print(userData);
        print(bytes);
      }
    } catch (error) {
      print(error);
    }
  }

  int _selectedIndex = 0;
  PageController? _pageController;
  _alert(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Do you really want to exit app ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    getUserFromLocalStorage();
  }

  @override
  void dispose() {
    _pageController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (() => _alert(context).then((value) => value!)),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SizedBox.expand(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: <Widget>[
                PosPage(data: userData),
                OrderScreen(data: userData),
                ProfileScreen(
                  data: userData,
                  bytes: byte ?? bytess,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavyBar(
            selectedIndex: _selectedIndex,
            showElevation: true, // use this to remove appBar's elevation
            onItemSelected: (index) => setState(() {
              _selectedIndex = index;
              _pageController!.animateToPage(index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease);
            }),
            items: [
              BottomNavyBarItem(
                icon: const Icon(Icons.apps),
                title: const Text('POS'),
                activeColor: Colors.blueGrey,
              ),
              BottomNavyBarItem(
                  icon: const Icon(Icons.table_chart),
                  title: const Text(
                    'Running Tables',
                    style: TextStyle(fontSize: 11),
                  ),
                  activeColor: Colors.blueGrey),
              BottomNavyBarItem(
                icon: const Icon(Icons.person),
                title: const Text('User'),
                activeColor: Colors.blueGrey,
              ),
            ],
          )),
    );
  }
}
