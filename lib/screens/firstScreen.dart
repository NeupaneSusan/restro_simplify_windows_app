

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/models/Tables.dart';
import 'package:restro_simplify/screens/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class MyFirstScreen extends StatefulWidget {
  const MyFirstScreen({Key? key}) : super(key: key);

  @override
  State<MyFirstScreen> createState() => _MyFirstScreenState();
}

class _MyFirstScreenState extends State<MyFirstScreen> {
  List<Tables> tables = <Tables>[];
  
  final url = "http://192.168.1.1/restroms/api";
  @override
  void initState() {
   fetchTables();
    super.initState();
  }
  Future<String> fetchTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var floorId = prefs.getString('floorId');
    var res = await http.get(Uri.parse(url + '/tables/$floorId'));
    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);
      List<Tables> cats = [];
      for (var data in jsonData['data']) {
        cats.add(Tables.fromJson(data));
      }
      if (mounted) {
        setState(() {
          tables = cats;
        });
      }

      return 'success';
    } else {
      throw "Can't get tables.";
    }
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
        child: Column(
          children: [
        const    Text('Select The Table',style:TextStyle(fontSize: 24 ,fontWeight: FontWeight.w500,color:Colors.blueGrey)),
            Expanded(
              child: GridView.count(
                                 shrinkWrap:true,
                                crossAxisCount: 10,
                                padding: const EdgeInsets.all(4.0),
                                children: tables.map((table) {
                                  return Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: InkWell(
                                      onTap: () {
                                        Globals.timer?.cancel();
                                        Globals.checkTime(context);
                                         FlutterBeep.beep();
                                        Navigator.push(context, MaterialPageRoute(builder: (_){
                                          return  HomeScreen(selectedTable: table,);
                                        }));
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.blueGrey,
                                            borderRadius:
                                                BorderRadius.all(Radius.circular(10))),
                                        child: Column(children: [
                                          const SizedBox(height: 10),
                                          const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(
                                                Icons.table_bar,
                                                color: Colors.white,
                                              )),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text(
                                              table.name.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  );
                                }).toList()),
            ),
          ],
        ),
      ),
    );
                  
                  
  }
}