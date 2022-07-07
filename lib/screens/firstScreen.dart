import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/audio_controller.dart';
import 'package:restro_simplify/models/Tables.dart';
import 'package:restro_simplify/screens/homescreen.dart';
import 'package:restro_simplify/screens/orderscreen.dart';
import 'package:restro_simplify/screens/pos.dart';
import 'package:restro_simplify/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class MyFirstScreen extends StatefulWidget {
  final dynamic userData;
  final Uint8List imageByte;
  const MyFirstScreen({Key? key, this.userData, required this.imageByte})
      : super(key: key);

  @override
  State<MyFirstScreen> createState() => _MyFirstScreenState();
}

class _MyFirstScreenState extends State<MyFirstScreen> {
  dynamic userData;
  Uint8List? imageByte;
  List<Tables> tables = <Tables>[];

  final url = "http://192.168.1.1/restroms/api";
  @override
  void initState() {
    fetchTables();
    super.initState();
    userData = widget.userData;
    imageByte = widget.imageByte;
  }

  Future<String> fetchTables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("object");
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
    return SafeArea(
      child: Scaffold(
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
              const SizedBox(
                height: 10,
              ),
              const Text('Select The Table',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey)),
              Expanded(
                child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 10,
                    padding: const EdgeInsets.all(4.0),
                    children: tables.map((table) {
                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: InkWell(
                          onTap: () {
                            Globals.timer?.cancel();
                            Globals.checkTime(context);
                            final myAudio = MyAudio();
                            myAudio.playSound();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) {
                              return PosPage(
                                selectedTable: table,
                                data: userData,
                              );
                            })).then((value) {
                              fetchTables();
                            });
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
              Container(
                height: 60,
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: kElevationToShadow[2],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom().copyWith(
                        shape:
                            MaterialStateProperty.resolveWith<OutlinedBorder>(
                                (_) {
                          return RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20));
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.blueGrey.shade50;
                            }

                            return Colors.white;
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            return Colors.blueGrey;
                          },
                        ),
                      ),
                      onPressed: () {
                        Globals.timer?.cancel();
                        Globals.checkTime(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) {
                          return PosPage(
                            data: userData,
                          );
                        })).then((value) {
                          fetchTables();
                        });
                      },
                      icon: const Icon(
                        Icons.apps,
                        size: 30,
                      ),
                      label: const Padding(
                        padding:
                            EdgeInsets.only(top: 8.0, bottom: 8.0, right: 2),
                        child: Text('POS', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom().copyWith(
                        shape:
                            MaterialStateProperty.resolveWith<OutlinedBorder>(
                                (_) {
                          return RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20));
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.blueGrey.shade50;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            return Colors.blueGrey;
                          },
                        ),
                      ),
                      onPressed: () {
                        Globals.timer?.cancel();
                        Globals.checkTime(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) {
                          return OrderScreen(
                            data: userData!,
                          );
                        })).then((value) {
                          fetchTables();
                        });
                      },
                      icon: const Icon(
                        Icons.table_chart,
                        size: 30,
                      ),
                      label: const Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text('Running Table',
                            style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom().copyWith(
                        shape:
                            MaterialStateProperty.resolveWith<OutlinedBorder>(
                                (_) {
                          return RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20));
                        }),
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.blueGrey.shade50;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            return Colors.blueGrey;
                          },
                        ),
                      ),
                      onPressed: () {
                        Globals.timer?.cancel();
                        Globals.checkTime(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) {
                          return ProfileScreen(
                            data: userData,
                            bytes: imageByte!,
                          );
                        })).then((value) {
                          fetchTables();
                        });
                      },
                      icon: const Icon(
                        Icons.person,
                        size: 30,
                      ),
                      label: const Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text('Profile', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
