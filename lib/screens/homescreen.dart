import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/screens/orderscreen.dart';

import 'package:restro_simplify/screens/pos.dart';
import 'package:restro_simplify/screens/profile.dart';
import 'package:restro_simplify/screens/slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  dynamic userData;
  Uint8List? byte;
  Uint8List bytess = Uint8List.fromList([]);
  var client = HttpClient();
  Future<ByteData> getImageBytesData(Uri key) async {
    final HttpClientRequest request = await client.getUrl(key);

    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      Uint8List bytes = Uint8List.fromList([]);
      return bytes.buffer.asByteData();
    }
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    return bytes.buffer.asByteData();
  }

  void getUserFromLocalStorage() async {
    try {
      Uint8List? bytes;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var res = await http
          .get(Uri.parse('http://192.168.1.1/restroms/api/qrcodes/fonepay'));
      if (res.statusCode == 200) {
        var jsonData = jsonDecode(res.body)['qrcode'];
        final ByteData imageData = await getImageBytesData(Uri.parse(jsonData));
        bytes = imageData.buffer.asUint8List();
        setState(() {
          userData = json.decode(prefs.getString('user')!);
          byte = bytes;
        });
      } else {
        setState(() {
          userData = json.decode(prefs.getString('user')!);
          byte = bytes;
        });
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
                Globals.timer?.cancel();
                Globals.checkTime(context);
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Globals.timer?.cancel();
                Globals.checkTime(context);
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
    Wakelock.enable();
    super.initState();
    _pageController = PageController();
    getUserFromLocalStorage();
    WidgetsBinding.instance.addObserver(this);
    Globals.checkTime(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MySlider()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Listener(
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
      child: WillPopScope(
        onWillPop: () async {
          _alert(context);
    
          return false;
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SizedBox.expand(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  Globals.timer?.cancel();
                  Globals.checkTime(context);
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
              showElevation: true,
              onItemSelected: (index) {
                Globals.timer?.cancel();
                Globals.checkTime(context);
                setState(() {
                  _selectedIndex = index;
                  _pageController!.animateToPage(index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease);
                });
              },
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
      ),
    );
  }
}
