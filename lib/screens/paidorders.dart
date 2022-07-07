// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:restro_simplify/controller/TimeController.dart';
import 'package:restro_simplify/controller/audio_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaidOrders extends StatefulWidget {
  const PaidOrders({Key? key, this.data}) : super(key: key);

  final data;

  @override
  _PaidOrdersState createState() => _PaidOrdersState();
}

class _PaidOrdersState extends State<PaidOrders> {
  List? orders = [];
  int count = 0;

  final url = "http://192.168.1.1/restroms/api";

  Future<String> getOrderData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.get("userid");

    final response =
        await http.get(Uri.parse(url + "/tableOrders/getPaidOrders/$id"));

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (mounted) {
        setState(() {
          orders = jsonData['data'];
          count = orders!.length;
        });
      }

      return "success";
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    getOrderData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Listener(
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
        child: Scaffold(
            body: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                  onPressed: () {
                    final myAudio = MyAudio();
                    Globals.timer?.cancel();
                    Globals.checkTime(context);
                    Navigator.pop(context);
                    myAudio.playSound();
                  },
                  icon: const Icon(Icons.arrow_back)),
              count != 0
                  ? Text(
                      "Current Running Tables : " + count.toString(),
                      style: const TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : SizedBox(),
              SizedBox()
            ]),
            count == 0
                ? GestureDetector(
                    onTap: () {
                      Globals.timer?.cancel();
                      Globals.checkTime(context);
                    },
                    child: Center(
                      heightFactor: height * .04,
                      child: const Text(
                        "No Paid Yets!",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Expanded(
                    child: GridView.count(
                      childAspectRatio: 0.8,
                      shrinkWrap: true,
                      physics: const ScrollPhysics(),
                      crossAxisCount: 8,
                      children: orders!.map((data) {
                        return Card(
                          color: Colors.green,
                          child: InkWell(
                            onTap: () {
                              Globals.timer?.cancel();
                              Globals.checkTime(context);
                              showToast("Bill already paid",
                                  context: context,
                                  position: StyledToastPosition.center,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green);
                            },
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 5.0),
                                child: Column(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 35.0),
                                      child: SizedBox(
                                          width: 40.0,
                                          child: Icon(
                                            Icons.table_bar,
                                            size: 35,
                                            color: Colors.white,
                                          )),
                                    ),
                                    Text(
                                      data['table_name'],
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Text(
                                        data['settled_time'],
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Card(
                                          color: Colors.lightGreen,
                                          elevation: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Rs. " + data['net_amount'],
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Text(
                                          "${data['payment_method']}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        )));
  }
}
